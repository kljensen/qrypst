# qrypst development tasks.

target := "wasm32-unknown-unknown"
wasm := "target/" + target + "/release/qrypst.wasm"

# rustc embeds source paths (panic locations in dependencies), and the cargo
# registry lives in a different place on every machine. Remapping both the
# registry and the checkout makes the wasm byte-identical across hosts, which
# is what lets CI check the committed file against a fresh build. CI sets the
# same flags; keep them in step.
remap := "--remap-path-prefix=" + env_var("HOME") + "/.cargo/registry/src=/registry --remap-path-prefix=" + justfile_directory() + "=/src"

# List the recipes.
default:
    @just --list

# Build the plugin and copy it to the repository root, where qrypst.typ
# expects it and where it is committed.
build:
    RUSTFLAGS="{{remap}}" cargo build --release --locked --target {{target}}
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
