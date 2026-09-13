//! Typst plugin: QR-encode bytes, return the module matrix.
//!
//! `encode(data, ecc)`:
//!   data: payload bytes, encoded in byte mode as-is (no charset guessing).
//!   ecc:  one ASCII byte, "L" | "M" | "Q" | "H".
//! Returns `n` followed by `n*n` bytes, row-major, 1 = dark module.
//! No quiet zone: the caller adds it, so it can be sized in paper units.
use qrcodegen::{QrCode, QrCodeEcc, QrSegment, Version};
use wasm_minimal_protocol::*;

initiate_protocol!();

#[wasm_func]
pub fn encode(data: &[u8], ecc: &[u8]) -> Result<Vec<u8>, String> {
    let ecl = match ecc {
        b"L" => QrCodeEcc::Low,
        b"M" => QrCodeEcc::Medium,
        b"Q" => QrCodeEcc::Quartile,
        b"H" => QrCodeEcc::High,
        other => return Err(format!("ecc must be L, M, Q or H, got {:?}", other)),
    };
    let segs = [QrSegment::make_bytes(data)];
    // Smallest version that fits at exactly `ecl`; mask chosen by penalty
    // score; ECC not boosted, so the level printed is the level asked for.
    let qr = QrCode::encode_segments_advanced(&segs, ecl, Version::MIN, Version::MAX, None, false)
        .map_err(|e| format!("payload of {} bytes does not fit: {:?}", data.len(), e))?;
    let n = qr.size();
    let mut out = Vec::with_capacity(1 + (n * n) as usize);
    out.push(n as u8);
    for y in 0..n {
        for x in 0..n {
            out.push(qr.get_module(x, y) as u8);
        }
    }
    Ok(out)
}

/// Same encoding, returned as `n`, a newline, then an SVG whose viewBox is
/// `n` units square, one path of horizontal runs. Typst draws it with one
/// `image()`; the caller sets width to `n * module` for exact module size.
#[wasm_func]
pub fn svg(data: &[u8], ecc: &[u8]) -> Result<Vec<u8>, String> {
    let m = encode(data, ecc)?;
    let n = m[0] as usize;
    let mut d = String::new();
    for y in 0..n {
        let mut x = 0;
        while x < n {
            if m[1 + y * n + x] == 1 {
                let x0 = x;
                while x < n && m[1 + y * n + x] == 1 {
                    x += 1;
                }
                d.push_str(&format!("M{x0} {y}h{}v1h-{}z", x - x0, x - x0));
            } else {
                x += 1;
            }
        }
    }
    Ok(format!(
        "{n}\n<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 {n} {n}\" shape-rendering=\"crispEdges\"><path d=\"{d}\"/></svg>"
    ).into_bytes())
}
