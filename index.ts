import path from "node:path";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import type { OpenClawPluginApi } from "openclaw/plugin-sdk/core";

const plugin = {
  id: "a2a-p2p",
  name: "A2A P2P",
  description: "A2A v1.0 peer-to-peer gateway for OpenClaw.",
  register(api: OpenClawPluginApi) {
    const stateDir = path.join(api.runtime.state.resolveStateDir(), "a2a-p2p");
    const logger = api.logger;

    const cfg = resolveConfig(api.pluginConfig ?? {});
    const taskStore = new TaskStore({ rootDir: stateDir, logger });

    api.registerTool(createListPeersTool(cfg));
    api.registerTool(createGetPeerTool(cfg));
    api.registerTool(createSendTool({ api, cfg, taskStore }));
    api.registerTool(createGetTaskTool({ taskStore }));
    api.registerTool(createCancelTaskTool({ taskStore }));
    api.registerTool(createRefreshPeerCardTool(cfg));

    api.registerHttpRoute({
      path: `${cfg.server.basePath}/.well-known/agent-card.json`,
      auth: "plugin",
      match: "exact",
      handler: async (req: any, res: any) => {
        try {
          if (!allowRemoteRequest(req, cfg.server.allowRemote)) {
            sendJson(res, 403, { error: "remote access disabled" });
            return;
          }
          sendJson(res, 200, buildAgentCard(cfg));
        } catch (err) {
          logger.error("a2a-p2p agent-card route failed", { error: String(err) });
          sendJson(res, 500, { error: "internal_error" });
        }
      },
    });

    api.registerHttpRoute({
      path: `${cfg.server.basePath}/jsonrpc`,
      auth: "plugin",
      match: "exact",
      handler: async (req: any, res: any) => {
        try {
          if (!allowRemoteRequest(req, cfg.server.allowRemote)) {
            sendJson(res, 403, { jsonrpc: "2.0", error: { code: -32000, message: "remote access disabled" }, id: null });
            return;
          }
          const authError = authorizeRequest(req, cfg.security);
          if (authError) {
            sendJson(res, 401, { jsonrpc: "2.0", error: { code: -32001, message: authError }, id: null });
            return;
          }
          const body = await readJsonBody(req, cfg.security.maxBodyBytes);
          const result = await handleJsonRpc({ api, cfg, taskStore, body });
          sendJson(res, 200, result);
        } catch (err) {
          logger.error("a2a-p2p jsonrpc route failed", { error: String(err) });
          sendJson(res, 500, { jsonrpc: "2.0", error: { code: -32603, message: String(err) }, id: null });
        }
      },
    });

    api.on("before_prompt_build", async () => ({
      appendSystemContext: [
        "A2A P2P plugin is available.",
        "Use a2a_list_peers to discover configured peers.",
        "Use a2a_send to send a message to another A2A agent.",
        "Use a2a_get_task / a2a_cancel_task for long-running remote tasks.",
      ].join(" "),
    }));
  },
};

export default plugin;

type ResolvedConfig = ReturnType<typeof resolveConfig>;

function resolveConfig(raw: Record<string, any>) {
  const server = raw.server ?? {};
  const agentCard = raw.agentCard ?? {};
  const routing = raw.routing ?? {};
  const security = raw.security ?? {};
  const peers = Array.isArray(raw.peers) ? raw.peers : [];
  return {
    server: {
      basePath: normalizeBasePath(server.basePath || "/a2a"),
      allowRemote: Boolean(server.allowRemote),
    },
    agentCard: {
      name: String(agentCard.name || "OpenClaw A2A Agent"),
      description: String(agentCard.description || "A2A-enabled OpenClaw agent"),
      version: String(agentCard.version || "1.0.0"),
      url: typeof agentCard.url === "string" ? agentCard.url : undefined,
      provider: String(agentCard.provider || "OpenClaw"),
      streaming: agentCard.streaming !== false,
      pushNotifications: Boolean(agentCard.pushNotifications),
      skills: Array.isArray(agentCard.skills) ? agentCard.skills : [{ id: "chat", name: "chat", description: "General-purpose text chat routed into OpenClaw" }],
    },
    routing: {
      sessionKey: typeof routing.sessionKey === "string" ? routing.sessionKey : undefined,
      mode: routing.mode === "system-event" ? "system-event" : "subagent",
      waitTimeoutMs: Number.isFinite(routing.waitTimeoutMs) ? Number(routing.waitTimeoutMs) : 30000,
    },
    security: {
      inboundAuth: security.inboundAuth === "none" ? "none" : "bearer",
      token: typeof security.token === "string" ? security.token : undefined,
      maxBodyBytes: Number.isFinite(security.maxBodyBytes) ? Number(security.maxBodyBytes) : 262144,
    },
    peers: peers.map((peer: any) => ({
      id: String(peer.id),
      name: String(peer.name),
      agentCardUrl: String(peer.agentCardUrl),
      description: typeof peer.description === "string" ? peer.description : undefined,
      labels: Array.isArray(peer.labels) ? peer.labels.map(String) : [],
      auth: {
        type: peer.auth?.type === "bearer" ? "bearer" : "none",
        token: typeof peer.auth?.token === "string" ? peer.auth.token : undefined,
      },
    })),
  };
}

function normalizeBasePath(value: string) {
  const trimmed = `/${String(value).trim().replace(/^\/+/, "").replace(/\/+$/, "")}`;
  return trimmed === "/" ? "/a2a" : trimmed;
}

function buildAgentCard(cfg: ResolvedConfig) {
  const endpoint = cfg.agentCard.url || `${cfg.server.basePath}/jsonrpc`;
  return {
    protocolVersion: "1.0.0",
    name: cfg.agentCard.name,
    description: cfg.agentCard.description,
    provider: { organization: cfg.agentCard.provider },
    url: endpoint,
    preferredTransport: "JSONRPC",
    defaultInputModes: ["text/plain"],
    defaultOutputModes: ["text/plain"],
    capabilities: {
      streaming: cfg.agentCard.streaming,
      pushNotifications: cfg.agentCard.pushNotifications,
    },
    skills: cfg.agentCard.skills,
  };
}

function createListPeersTool(cfg: ResolvedConfig) {
  return {
    name: "a2a_list_peers",
    description: "List configured A2A peers.",
    parameters: { type: "object", additionalProperties: false, properties: {} },
    async execute() {
      return toolJson({ peers: cfg.peers });
    },
  };
}

function createGetPeerTool(cfg: ResolvedConfig) {
  return {
    name: "a2a_get_peer",
    description: "Get one configured A2A peer by id or name.",
    parameters: {
      type: "object",
      additionalProperties: false,
      properties: {
        id: { type: "string" },
        name: { type: "string" }
      }
    },
    async execute(_id: string, params: any) {
      const peer = findPeer(cfg, params?.id, params?.name);
      if (!peer) throw new Error("peer not found");
      return toolJson(peer);
    },
  };
}

function createSendTool({ api, cfg, taskStore }: { api: OpenClawPluginApi; cfg: ResolvedConfig; taskStore: TaskStore }) {
  return {
    name: "a2a_send",
    description: "Send a text message to a remote A2A peer.",
    parameters: {
      type: "object",
      additionalProperties: false,
      required: ["peer", "message"],
      properties: {
        peer: { type: "string" },
        message: { type: "string" },
        contextId: { type: "string" },
        wait: { type: "boolean", default: true }
      }
    },
    async execute(_toolCallId: string, params: any) {
      const peer = findPeer(cfg, params?.peer, params?.peer);
      if (!peer) throw new Error(`peer not found: ${String(params?.peer || "")}`);
      const card = await fetchJson(peer.agentCardUrl, peer.auth);
      const endpoint = String(card.url || "").trim();
      if (!endpoint) throw new Error("peer agent card missing url");
      const taskId = `task_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
      await taskStore.put({ id: taskId, state: "submitted", peerId: peer.id, direction: "outbound", createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
      const payload = {
        jsonrpc: "2.0",
        id: taskId,
        method: "message/send",
        params: {
          message: {
            role: "user",
            parts: [{ type: "text", text: String(params.message) }]
          },
          metadata: {
            contextId: typeof params.contextId === "string" ? params.contextId : undefined,
            source: "openclaw-a2a-p2p"
          }
        }
      };
      const response = await postJson(endpoint, payload, peer.auth);
      await taskStore.put({ id: taskId, state: "completed", peerId: peer.id, direction: "outbound", createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(), result: response?.result ?? response, raw: response });
      return toolJson({ taskId, peer: peer.id, response });
    },
  };
}

function createGetTaskTool({ taskStore }: { taskStore: TaskStore }) {
  return {
    name: "a2a_get_task",
    description: "Get a locally tracked A2A task by taskId.",
    parameters: {
      type: "object",
      additionalProperties: false,
      required: ["taskId"],
      properties: { taskId: { type: "string" } }
    },
    async execute(_toolCallId: string, params: any) {
      const task = await taskStore.get(String(params?.taskId || ""));
      if (!task) throw new Error("task not found");
      return toolJson(task);
    },
  };
}

function createCancelTaskTool({ taskStore }: { taskStore: TaskStore }) {
  return {
    name: "a2a_cancel_task",
    description: "Mark a locally tracked A2A task as canceled. Does not force remote cancel yet.",
    parameters: {
      type: "object",
      additionalProperties: false,
      required: ["taskId"],
      properties: { taskId: { type: "string" } }
    },
    async execute(_toolCallId: string, params: any) {
      const id = String(params?.taskId || "");
      const existing = await taskStore.get(id);
      if (!existing) throw new Error("task not found");
      const next = { ...existing, state: "canceled", updatedAt: new Date().toISOString() };
      await taskStore.put(next);
      return toolJson(next);
    },
  };
}

function createRefreshPeerCardTool(cfg: ResolvedConfig) {
  return {
    name: "a2a_refresh_peer_card",
    description: "Fetch and return the current agent card for a configured peer.",
    parameters: {
      type: "object",
      additionalProperties: false,
      required: ["peer"],
      properties: { peer: { type: "string" } }
    },
    async execute(_toolCallId: string, params: any) {
      const peer = findPeer(cfg, params?.peer, params?.peer);
      if (!peer) throw new Error("peer not found");
      const card = await fetchJson(peer.agentCardUrl, peer.auth);
      return toolJson({ peer: peer.id, card });
    },
  };
}

async function handleJsonRpc({ api, cfg, taskStore, body }: { api: OpenClawPluginApi; cfg: ResolvedConfig; taskStore: TaskStore; body: any }) {
  const id = body?.id ?? null;
  const method = String(body?.method || "");
  if (body?.jsonrpc !== "2.0") {
    return { jsonrpc: "2.0", id, error: { code: -32600, message: "invalid jsonrpc version" } };
  }
  if (method === "agent/card" || method === "agent/getCard") {
    return { jsonrpc: "2.0", id, result: buildAgentCard(cfg) };
  }
  if (method === "tasks/get") {
    const task = await taskStore.get(String(body?.params?.id || body?.params?.taskId || ""));
    if (!task) return { jsonrpc: "2.0", id, error: { code: -32004, message: "task not found" } };
    return { jsonrpc: "2.0", id, result: task };
  }
  if (method === "tasks/cancel") {
    const taskId = String(body?.params?.id || body?.params?.taskId || "");
    const existing = await taskStore.get(taskId);
    if (!existing) return { jsonrpc: "2.0", id, error: { code: -32004, message: "task not found" } };
    const next = { ...existing, state: "canceled", updatedAt: new Date().toISOString() };
    await taskStore.put(next);
    return { jsonrpc: "2.0", id, result: next };
  }
  if (method === "message/send") {
    return handleInboundMessage({ api, cfg, taskStore, body });
  }
  return { jsonrpc: "2.0", id, error: { code: -32601, message: `method not supported: ${method}` } };
}

async function handleInboundMessage({ api, cfg, taskStore, body }: { api: OpenClawPluginApi; cfg: ResolvedConfig; taskStore: TaskStore; body: any }) {
  const id = body?.id ?? `task_${Date.now()}`;
  const taskId = `in_${String(id)}`;
  const messageText = extractTextFromA2A(body?.params?.message);
  const task = {
    id: taskId,
    state: "working",
    direction: "inbound",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    request: body?.params?.message,
  };
  await taskStore.put(task);

  let responseText = "Received by OpenClaw A2A plugin.";
  if (cfg.routing.mode === "system-event") {
    await api.runtime.system.enqueueSystemEvent(`[A2A reminder/inbound] ${messageText}`);
    responseText = `Accepted inbound A2A message and enqueued it as a system event: ${messageText}`;
  } else if (cfg.routing.sessionKey) {
    const run = await api.runtime.subagent.run({
      sessionKey: cfg.routing.sessionKey,
      message: `Inbound A2A message:\n\n${messageText}`,
      deliver: false,
      idempotencyKey: `a2a-${taskId}`,
    });
    await api.runtime.subagent.waitForRun({ runId: run.runId, timeoutMs: cfg.routing.waitTimeoutMs });
    const transcript = await api.runtime.subagent.getSessionMessages({ sessionKey: cfg.routing.sessionKey, limit: 8 });
    responseText = extractAssistantTextFromMessages(transcript.messages) || `Accepted inbound A2A message: ${messageText}`;
  } else {
    responseText = [
      "Inbound A2A message received, but no local routing.sessionKey is configured.",
      `Message: ${messageText}`,
    ].join(" ");
  }

  const completed = {
    ...task,
    state: "completed",
    updatedAt: new Date().toISOString(),
    result: {
      role: "agent",
      parts: [{ type: "text", text: responseText }],
    },
  };
  await taskStore.put(completed);

  return {
    jsonrpc: "2.0",
    id,
    result: {
      id: taskId,
      status: { state: "completed" },
      messages: [completed.result],
      artifacts: [],
    },
  };
}

function extractTextFromA2A(message: any) {
  const parts = Array.isArray(message?.parts) ? message.parts : [];
  const text = parts
    .map((part: any) => {
      if (typeof part?.text === "string") return part.text;
      if (part?.type === "data") return JSON.stringify(part.data ?? {}, null, 2);
      if (part?.type === "file") return `[file:${part?.name || part?.mimeType || "attachment"}]`;
      return "";
    })
    .filter(Boolean)
    .join("\n\n")
    .trim();
  return text || "(empty inbound message)";
}

function extractAssistantTextFromMessages(messages: any[]) {
  const items = Array.isArray(messages) ? [...messages].reverse() : [];
  for (const item of items) {
    const text = extractTextFromUnknownMessage(item);
    if (text) return text;
  }
  return undefined;
}

function extractTextFromUnknownMessage(message: any): string | undefined {
  if (!message) return undefined;
  if (typeof message.text === "string" && message.text.trim()) return message.text.trim();
  if (typeof message.content === "string" && message.content.trim()) return message.content.trim();
  if (Array.isArray(message.content)) {
    const text = message.content.map((part: any) => typeof part?.text === "string" ? part.text : "").filter(Boolean).join("\n").trim();
    if (text) return text;
  }
  if (Array.isArray(message.parts)) {
    const text = message.parts.map((part: any) => typeof part?.text === "string" ? part.text : "").filter(Boolean).join("\n").trim();
    if (text) return text;
  }
  return undefined;
}

function findPeer(cfg: ResolvedConfig, id?: string, name?: string) {
  return cfg.peers.find((peer) => peer.id === id || peer.name === name);
}

function authorizeRequest(req: any, security: ResolvedConfig["security"]) {
  if (security.inboundAuth === "none") return null;
  if (!security.token) return "plugin misconfigured: missing security.token";
  const header = String(req?.headers?.authorization || req?.headers?.Authorization || "");
  const expected = `Bearer ${security.token}`;
  return header === expected ? null : "unauthorized";
}

function allowRemoteRequest(req: any, allowRemote: boolean) {
  if (allowRemote) return true;
  const remote = String(req?.socket?.remoteAddress || req?.ip || "");
  return remote === "127.0.0.1" || remote === "::1" || remote === "::ffff:127.0.0.1" || remote === "";
}

async function readJsonBody(req: any, maxBytes: number) {
  const chunks: Buffer[] = [];
  let total = 0;
  for await (const chunk of req) {
    const buf = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buf.length;
    if (total > maxBytes) throw new Error(`request body exceeds maxBodyBytes (${maxBytes})`);
    chunks.push(buf);
  }
  const raw = Buffer.concat(chunks).toString("utf8").trim();
  return raw ? JSON.parse(raw) : {};
}

function sendJson(res: any, status: number, body: unknown) {
  res.statusCode = status;
  res.setHeader?.("content-type", "application/json; charset=utf-8");
  res.end?.(JSON.stringify(body, null, 2));
}

function toolJson(payload: unknown) {
  return {
    content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
    details: payload,
  };
}

async function fetchJson(url: string, auth?: { type: string; token?: string }) {
  const headers: Record<string, string> = { accept: "application/json" };
  if (auth?.type === "bearer" && auth.token) headers.authorization = `Bearer ${auth.token}`;
  const response = await fetch(url, { headers });
  if (!response.ok) throw new Error(`fetch failed ${response.status}: ${url}`);
  return response.json();
}

async function postJson(url: string, body: unknown, auth?: { type: string; token?: string }) {
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (auth?.type === "bearer" && auth.token) headers.authorization = `Bearer ${auth.token}`;
  const response = await fetch(url, { method: "POST", headers, body: JSON.stringify(body) });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`post failed ${response.status}: ${text}`);
  }
  return response.json();
}

class TaskStore {
  rootDir: string;
  logger: OpenClawPluginApi["logger"];

  constructor(params: { rootDir: string; logger: OpenClawPluginApi["logger"] }) {
    this.rootDir = params.rootDir;
    this.logger = params.logger;
  }

  async put(task: any) {
    await mkdir(this.rootDir, { recursive: true });
    const file = path.join(this.rootDir, `${task.id}.json`);
    await writeFile(file, JSON.stringify(task, null, 2), "utf8");
  }

  async get(id: string) {
    try {
      const file = path.join(this.rootDir, `${id}.json`);
      const raw = await readFile(file, "utf8");
      return JSON.parse(raw);
    } catch (err) {
      if ((err as NodeJS.ErrnoException)?.code === "ENOENT") return null;
      this.logger.error("a2a-p2p task store get failed", { id, error: String(err) });
      throw err;
    }
  }
}
