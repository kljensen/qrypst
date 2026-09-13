# qrypst development tasks.

target := "wasm32-unknown-unknown"
wasm := "target/" + target + "/release/qrypst.wasm"

# List the recipes.
default:
    @just --list

# Build the plugin and copy it to the repository root, where qrypst.typ
# expects it and where it is committed.
build:
    cargo build --release --locked --target {{target}}
    cp {{wasm}} qrypst.wasm

# Fail if the committed qrypst.wasm is not what the source builds.
check-wasm: build
    git diff --exit-code --stat -- qrypst.wasm

fmt-check:
    cargo fmt --all -- --check

lint:
    cargo clippy --all-targets --locked -- -D warnings

# Compile tests/smoke.typ, rasterise it, and decode every code with zbar.
test: build
    tests/smoke.sh

# Everything CI runs, in CI's order.
ci: fmt-check lint check-wasm test
