# pi-llamacpp

Pi provider extension for running Pi self-managed local
[llama.cpp](https://github.com/ggml-org/llama.cpp) inference.

The extension registers Qwen3.6 GGUF models under the `llamacpp` provider,
downloads/builds a matching llama.cpp runtime and downloads the selected GGUF on
first use, starts `llama-server`, and stops it automatically when pi shuts down.

## Models

Currently registered:

- `llamacpp/qwen-3.6-2bit`
- `llamacpp/qwen-3.6-4bit`
- `llamacpp/qwen-3.6-8bit`

All are downloaded from
[`havenoammo/Qwen3.6-35B-A3B-MTP-GGUF`](https://huggingface.co/havenoammo/Qwen3.6-35B-A3B-MTP-GGUF).
These files need llama.cpp MTP/NextN support, so the default runtime path builds
a pinned snapshot of a pull request against llama.cpp instead of using the stock
binary release.

## Install

```sh
pi install https://github.com/mitsuhiko/pi-llamacpp
```

For local development from this checkout:

```sh
./install-pi-extension-local.sh
```

Then restart Pi or run `/reload`.

## Runtime layout

Runtime state is kept under `~/.pi/llamacpp`:

- `source/`: pinned llama.cpp source snapshots built locally (default: PR #22673 snapshot for MTP/NextN support)
- `runtime/`: extracted llama.cpp release archives when `LLAMACPP_RUNTIME_KIND=release`
- `downloads/`: release archives and resumable `.part` files
- `models/havenoammo/Qwen3.6-35B-A3B-MTP-GGUF/`: cached GGUF model files
- `clients/`: active Pi process leases
- `server.json`: managed `llama-server` state
- `log`: download/extract/server/watchdog log

The managed server binds to a random localhost port by default and records the
active endpoint in `server.json`. Set `LLAMACPP_PORT` only if you explicitly
want a fixed port.

## Debugging

Use `/llamacpp` inside Pi to show the live llama.cpp log, `/llamacpp status` for
paths/status, and `/llamacpp stop` to stop the managed server when no other
leases are active.
