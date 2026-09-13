// One page per code. tests/smoke.sh rasterises each page and checks that
// zbar decodes exactly the payload printed under it.
#import "../qrypst.typ": qr, matrix

#set page(width: 80mm, height: 80mm, margin: 5mm)
#set text(size: 6pt, font: "DejaVu Sans Mono", fallback: true)

#let cases = (
  ("hello", "M"),
  ("https://example.com/path?x=1&y=2", "L"),
  // 120 bytes of base64-looking text at every level: the sizes a print
  // manifest code lands in.
  ("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGE=", "L"),
  ("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGE=", "M"),
  ("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGE=", "Q"),
  ("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGE=", "H"),
  // The smallest module size the tests rasterise legibly at 300 dpi.
  ("TQ2|mgt-656-fall-2026|front-end-1|an7afwwl|0042|g1|903b83a5", "M"),
)

#for (payload, ecc) in cases {
  align(center)[
    #qr(payload, module: 0.6mm, ecc: ecc)
    #v(2mm)
    #raw(payload)
  ]
  pagebreak(weak: true)
}

// The matrix API agrees with the drawn symbol on size, and the finder
// pattern is where the spec puts it.
#let m = matrix("hello")
#assert(m.len() == 21, message: "version 1 is 21 modules")
#assert(m.at(0).slice(0, 7) == (true, true, true, true, true, true, true), message: "top-left finder row")
