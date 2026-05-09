# pi-llamacpp

Pi provider extension for running managed local [llama.cpp](https://github.com/ggml-org/llama.cpp) inference.

The extension registers Qwen3.6 GGUF models under the `llamacpp` provider, downloads/builds a matching llama.cpp runtime on first use, downloads the selected GGUF on first use, starts `llama-server`, and stops it via a watchdog when no Pi clients are left.

## Models

Currently registered:

- `llamacpp/qwen-3.6-2bit`
- `llamacpp/qwen-3.6-4bit`
- `llamacpp/qwen-3.6-6bit`
- `llamacpp/qwen-3.6-8bit`

All are downloaded from [`havenoammo/Qwen3.6-35B-A3B-MTP-GGUF`](https://huggingface.co/havenoammo/Qwen3.6-35B-A3B-MTP-GGUF).  The 3-bit and 5-bit quants are intentionally not registered. These files need llama.cpp MTP/NextN support, so the default runtime path builds a pinned snapshot of PR #22673 instead of using the stock `b9090` binary release.

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

- `source/` — pinned llama.cpp source snapshots built locally (default: PR #22673 snapshot for MTP/NextN support)
- `runtime/` — extracted llama.cpp release archives when `LLAMACPP_RUNTIME_KIND=release`
- `downloads/` — release archives and resumable `.part` files
- `models/havenoammo/Qwen3.6-35B-A3B-MTP-GGUF/` — cached GGUF model files
- `clients/` — active Pi process leases
- `server.json` — managed `llama-server` state
- `log` — download/extract/server/watchdog log

The managed server binds to a random localhost port by default and records the active endpoint in `server.json`. Set `LLAMACPP_PORT` only if you explicitly want a fixed port.

## Configuration

Environment overrides:

- `LLAMACPP_RUNTIME_KIND`: `source` or `release` (default `source`; required for these MTP GGUFs)
- `LLAMACPP_SOURCE_REF`: llama.cpp source commit/ref to build (default pinned PR #22673 head)
- `LLAMACPP_SOURCE_REPO`: source repository (default `ggml-org/llama.cpp`)
- `LLAMACPP_SOURCE_URL`: exact source archive URL override
- `LLAMACPP_CMAKE_ARGS`: extra whitespace-separated CMake configure args
- `LLAMACPP_BUILD_ARGS`: extra whitespace-separated CMake build args
- `LLAMACPP_BUILD_JOBS`: parallel build jobs (default auto)
- `LLAMACPP_RELEASE_TAG`: llama.cpp release tag when `LLAMACPP_RUNTIME_KIND=release` (default `b9090`)
- `LLAMACPP_RELEASE_REPO`: release repository (default `ggml-org/llama.cpp`)
- `LLAMACPP_RELEASE_ASSET_URL`: exact release archive URL override
- `LLAMACPP_RELEASE_ASSET_NAME`: archive name when using `LLAMACPP_RELEASE_ASSET_URL`
- `LLAMACPP_RUNTIME_DIR`: use an existing extracted/built llama.cpp runtime containing `llama-server`
- `LLAMACPP_SERVER_BINARY`: use a specific `llama-server` binary
- `LLAMACPP_PORT`: fixed managed server port (default unset, pick a random free localhost port)
- `LLAMACPP_CTX_SIZE`: server context size and registered context window (default `262144`)
- `LLAMACPP_MAX_TOKENS`: registered max output tokens (default `65536`)
- `LLAMACPP_GPU_LAYERS`: passed to `--n-gpu-layers`
- `LLAMACPP_PARALLEL`: passed to `--parallel`
- `LLAMACPP_ENABLE_MTP=0`: disable `--spec-type mtp --spec-draft-n-max 3` (enabled by default; requires the default source build or another llama.cpp build with MTP support)
- `LLAMACPP_MTP_DRAFT_N_MAX`: override MTP draft max (default `3`, matching the model repo recommendation)
- `LLAMACPP_SERVER_ARGS`: extra whitespace-separated `llama-server` args
- `LLAMACPP_READY_TIMEOUT_MS`: server startup timeout

Use `/llamacpp` inside Pi to show the live llama.cpp log, `/llamacpp status` for paths/status, and `/llamacpp stop` to stop the managed server when no other leases are active.
