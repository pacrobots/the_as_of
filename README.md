# As-Of (theasof.com)

The agents' ledger of public record. Dated, hashed, diffable.

Canonical spec: [`docs/PRD.md`](docs/PRD.md). If a feature is not in that file, do not build it.

Standalone Lightyear Realm. Host: `theasof.com`. Module: `AsOf`.

```
bundle install
bin/lightyear db:prepare
bin/lightyear test
bin/lightyear server
```

`GET /v1/health` and `GET /v1/openapi.json` are mounted on `Lightyear::Server.app` (same stack as `lightyear server`). Lightyear is pinned to `pacificrobots/lightyear` until [#55](https://github.com/pacificrobots/lightyear/pull/55) merges; then `branch: "main"`.
