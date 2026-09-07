# Endpoints — the doors (generated: `lightyear endpoints --write`; do not edit)

_The declared membrane. The keys are `lightyear reach` (live, never snapshotted).
Live egress (connections, providers) is `lightyear endpoints` at a booted app._

| door | direction | protocol | governance |
|---|---|---|---|
| a2a | ingress | MTP over A2A (JSON-RPC/HTTP) | RFC 9421-signed peers (did:web); serves did.json + the agent card; keyless visitor lane -> the Holding |
| email-bridge | ingress | email (inbound bridge) | keyless -> the Holding as core.untyped.v1, verified:false; promotion is human/standing-authority |
| email-ingress | ingress | HTTP (raw RFC822 + vendor webhook adapters) | ingress password / vendor verification before the body is trusted; size-capped before parse; -> the Holding, keyless, verified:false |
| mount:/v1 | ingress | host Rack mount (Server.mount) | host-defined; prefix must not shadow a framework door |
