# qrypst

A tiny [Typst](https://typst.app) plugin that QR-encodes bytes and hands back
the module matrix. About 40 lines of Rust around Nayuki's
[qrcodegen](https://crates.io/crates/qrcodegen), compiled to a 41 KB WebAssembly
file. No quiet zone, no styling, no SVG library: you say how big a module is on
paper, and that is how big it is.

## Why

The existing Typst QR packages carry a lot of machinery for the one thing a
document usually needs. `cades` runs a JavaScript QR library inside a
JavaScript interpreter compiled to WebAssembly, and costs about 3.4 seconds per
code. `tiaoma` compiles all of Zint and costs about 0.3 seconds. This plugin
costs about 7 milliseconds per code, and the number of modules it reports is
exact, so the printed module size is something you set rather than something you
infer from a scaled image.

## Use

Copy `qrypst.wasm` and `qrypst.typ` next to your document.

```typst
#import "qrypst.typ": qr

#qr("https://example.com", module: 0.5mm)
#qr(bytes-payload, module: 0.635mm, ecc: "Q", quiet: 4)
```

- `module`: printed side of one module. The symbol is `n * module` square
  plus the quiet zone.
- `ecc`: `"L"`, `"M"`, `"Q"` or `"H"`. The version is the smallest that fits at
  exactly that level; the level is never silently raised.
- `quiet`: width of the white border in modules. The QR specification says 4.

Two lower-level functions are exported for callers that want to draw modules
themselves: `encode(payload, ecc:)` returns `(n, svg-bytes)`, and
`matrix(payload, ecc:)` returns `n` rows of `n` booleans, `true` for dark.

Payloads are encoded in byte mode as given. Pass a `str` and it is UTF-8; pass
`bytes` and they go in verbatim.

## Build

```sh
rustup target add wasm32-unknown-unknown
cargo build --release --target wasm32-unknown-unknown
cp target/wasm32-unknown-unknown/release/qrypst.wasm .
```

Or `just build`. The built `qrypst.wasm` is committed so that Typst users need
no Rust toolchain.

## Development

```sh
just build        # build the plugin and copy qrypst.wasm to the repo root
just test         # compile tests/smoke.typ and decode every code with zbar
just ci           # everything CI runs, in CI's order
```

The toolchain is pinned in `rust-toolchain.toml`, wasm target included, so a
bare `rustup toolchain install` in the checkout sets up everything. The smoke
test needs `typst`, `zbarimg` (Homebrew `zbar`) and `pdftoppm` (Homebrew
`poppler`). Run `just build` before committing a change to `src/`: CI decodes
the committed `qrypst.wasm` and then a fresh build of the source, and both
must pass. The two are not compared byte for byte, because the macOS and
Linux toolchains do not produce identical wasm even with source paths
remapped; `just check-wasm` does that comparison on one machine.

Releases are tags: `git tag v0.1.0 && git push --tags` builds the plugin on
Linux twice from a clean tree to prove the build is reproducible there, and
attaches that build, `qrypst.typ` and `SHA256SUMS` to a GitHub release. Pin
by those checksums, not by the file in git.

## Numbers

Measured with `typst compile --timings` on an M-series Mac, Typst 0.14.2, one
120-byte payload at level M (version 7, 45 modules):

| encoder | per code |
|---|---|
| cades 0.3.1 | ~3.4 s |
| tiaoma 0.3.0 | ~0.3 s |
| qrypst, `opt-level = 3` | ~7 ms |

Typst runs plugins under an interpreter, which is why this is milliseconds and
not microseconds, and why `opt-level = 3` matters: size-optimised builds run
about 2.7 times slower there.

## Licence

qrypst's own code is released into the public domain under the
[Unlicense](UNLICENSE). The compiled plugin embeds
[qrcodegen](https://github.com/nayuki/QR-Code-generator) (MIT) and
[wasm-minimal-protocol](https://github.com/typst-community/wasm-minimal-protocol)
(Unlicense); qrcodegen's licence is not covered by the dedication.
