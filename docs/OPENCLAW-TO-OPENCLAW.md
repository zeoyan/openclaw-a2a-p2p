# OpenClaw-to-OpenClaw quick flow

This file describes the simplest two-node communication pattern.

## Node A

1. run `./scripts/install-and-init.sh`
2. copy the generated `peer-info.json`

## Node B

1. run `./scripts/install-and-init.sh`
2. copy the generated `peer-info.json`

## Exchange

- import B into A
- import A into B

After that:

- A can send to B
- B can send to A

## Important

This only works if the actual network path between the two nodes is reachable.
Peer-info exchange does not bypass firewall, NAT, loopback-only binding, or cloud security groups.
