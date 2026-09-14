qrypst draws QR codes with an exact printed module size: you say how big one
module is on paper, and that is how big it prints. It is about 40 lines of Rust
around Nayuki's [qrcodegen](https://github.com/nayuki/QR-Code-generator),
compiled to a 42 KB WebAssembly plugin, and it takes about 7 milliseconds per
code. It reports the module count, so nothing is inferred from a scaled image,
and it adds no styling of its own.

## Usage

```typst
#import "@preview/qrypst:0.1.1": qr

#qr("https://example.com", module: 0.5mm)
```

That payload needs version 2 at level M, which is 25 modules on a side, so the
symbol prints 12.5 mm square inside a white quiet zone 2 mm wide.

```typst
#qr(payload, module: 0.635mm, ecc: "Q", quiet: 4)
```

## Install

**From the registry.** Import `@preview/qrypst:0.1.1` as above. Typst fetches
the package the first time it is used; there is nothing else to install.

**Vendored from a release.** If you would rather not depend on the registry,
copy two files from a [GitHub release](https://github.com/kljensen/qrypst/releases)
next to your document and check them against the release's `SHA256SUMS`:

```sh
v=v0.1.0
base=https://github.com/kljensen/qrypst/releases/download/$v
curl -fsSLO $base/qrypst.wasm
curl -fsSLO $base/qrypst.typ
curl -fsSLO $base/SHA256SUMS
sha256sum --check SHA256SUMS   # on macOS: shasum -a 256 --check SHA256SUMS
```

For v0.1.0 the checksum file reads:

```
37842963245abfd50dc3278a841f17f59ca3f0a123c1df23484e26feee3b573c  qrypst.wasm
7d8359bbb06379aab49545d3a05e97d65cbfab4b066eb6810859fee783a338b5  qrypst.typ
```

Then `#import "qrypst.typ": qr` by relative path. `qrypst.typ` loads
`qrypst.wasm` from its own directory, so the two files move together, and that
directory must be inside the project root (`typst compile --root`; by default
the document's own directory).

**Web app.** The Typst web app does not take an uploaded `.wasm` file, so use
the registry import there.

## API

| Function | Arguments | Returns |
|---|---|---|
| `qr(payload, module: 0.5mm, ecc: "M", quiet: 4)` | `payload`: `str` or `bytes`. `module`: `length`, the printed side of one module. `ecc`: `"L"`, `"M"`, `"Q"` or `"H"`. `quiet`: `int`, width of the white border in modules. | A `box`, `(n + 2 * quiet) * module` on a side: the symbol on a white fill, the quiet zone as inset. |
| `encode(payload, ecc: "M")` | `payload` and `ecc` as above. | `(n, svg)`: `n` is an `int`, the module count; `svg` is `bytes` holding an SVG with a `0 0 n n` viewBox and no quiet zone. Draw it with `image(svg, format: "svg", width: n * module)`. |
| `matrix(payload, ecc: "M")` | `payload` and `ecc` as above. | An `array` of `n` rows, each an `array` of `n` `bool`, `true` for a dark module. |

A payload that does not fit at the requested level (more than 2953 bytes at
`"L"`, fewer at the other levels) stops compilation with
`plugin errored with: payload of 3000 bytes does not fit: DataOverCapacity(24020, 18672)`,
the two numbers being bits needed and bits available. An `ecc` other than the
four letters stops it with `ecc must be L, M, Q or H, got [88]`, showing the
byte it received.

## Notes

- Payloads are encoded in byte mode as given. A `str` goes in as UTF-8; `bytes`
  go in verbatim. There is no numeric or alphanumeric mode, so a payload of
  digits alone lands in a slightly larger version than a mode-switching encoder
  would pick.
- The version, and so the size, is the smallest that fits at the requested
  level. It is chosen for you and reported as `n`: 21 modules for version 1 up
  to 177 for version 40.
- The error-correction level is exactly the one asked for. It is never raised
  silently, even when a higher level would fit in the same version.
- The symbol `encode` and `matrix` return has no quiet zone. `qr` draws one
  `quiet` modules wide (the QR specification says 4), so the clearance is in
  paper units too.

## Performance

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

## Building from source

Check out the tag you want (`git checkout v0.1.1`) and run `just build`. That
runs `cargo build --release --locked --target wasm32-unknown-unknown` with the
toolchain pinned in `rust-toolchain.toml` and copies the result to
`qrypst.wasm`. `just test` compiles `tests/smoke.typ` and decodes every code
with zbar; it needs `typst`, `zbarimg` (Homebrew `zbar`) and `pdftoppm`
(Homebrew `poppler`).

Releases are built on Linux: the release workflow builds the tag twice from a
clean tree, refuses to publish unless the two builds are byte-identical, and
attaches the build, `qrypst.typ` and `SHA256SUMS`. A macOS build of the same
source is not byte-identical to the Linux one, so compare against the release
checksums rather than against a local build.

## Updating a vendored copy

Fetch the new release's `qrypst.wasm`, `qrypst.typ` and `SHA256SUMS` as in
Install, run `sha256sum --check`, replace both files at once (they are released
together and must match), and compile one document to confirm. Registry users
change the version in the import line instead.

## Licence

qrypst's own files, `qrypst.typ`, `src/lib.rs` and everything else in this
repository, are released into the public domain under the
[Unlicense](LICENSE). The compiled `qrypst.wasm` also contains two
dependencies, which keep their own licences:

- [qrcodegen](https://github.com/nayuki/QR-Code-generator) is
  Copyright (c) Project Nayuki, under the
  [MIT licence](https://github.com/nayuki/QR-Code-generator/blob/v1.8.0/Readme.markdown#license).
  The public-domain dedication does not cover it.
- [wasm-minimal-protocol](https://github.com/typst-community/wasm-minimal-protocol)
  is under the
  [Unlicense](https://github.com/typst-community/wasm-minimal-protocol/blob/main/LICENSE).

## Alternatives

- [cades](https://typst.app/universe/package/cades) runs a JavaScript QR
  library under the jogs interpreter plugin, and can colour the code; the
  most widely used, and the slowest.
- [tiaoma](https://typst.app/universe/package/tiaoma) is Zint compiled to
  WebAssembly: QR plus dozens of other barcode symbologies with Zint's own
  options. The one to use if you need anything other than a QR code.
