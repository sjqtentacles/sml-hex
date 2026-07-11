# sml-hex

[![CI](https://github.com/sjqtentacles/sml-hex/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-hex/actions/workflows/ci.yml)

A small, portable hexadecimal encoder/decoder for Standard ML.

`sml-hex` converts between bytes and their hex-digit representation, with both
byte-oriented (`Word8Vector.vector`) and string-oriented entry points. Strict
`decode` returns `NONE` on an odd number of digits or any non-hex character
(but tolerates mixed case); a tolerant `decodeLoose` additionally ignores
whitespace and a `0x`/`0X` prefix. There are also digit/byte helpers and an
xxd-style `hexdump`.

## Portability

Pure Standard ML using only the Basis library -- no FFI, no threads. Verified
on **MLton** and **Poly/ML**, with byte-for-byte identical output.

## Building and testing

```sh
make test        # build + run the suite under MLton (default)
make test-poly   # run the suite under Poly/ML
make all-tests   # run under both
make clean
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-hex
smlpkg sync
```

Then reference the library basis from your own `.mlb`:

```
lib/github.com/sjqtentacles/sml-hex/hex.mlb
```

For Poly/ML, `use` the `hex.sig` and `hex.sml` sources in order.

## Usage

```sml
val s = Hex.encode (Word8Vector.fromList [0wxDE, 0wxAD, 0wxBE, 0wxEF])
(* s = "deadbeef" *)

val SOME bytes = Hex.decode "deadbeef"   (* accepts "DEADBEEF" too *)
val NONE       = Hex.decode "abc"        (* odd length            *)
val NONE       = Hex.decode "zz"         (* non-hex character      *)

val h = Hex.encodeString "ML"            (* "4d4c" *)
val SOME "ML" = Hex.decodeString "4d4c"

(* digit / byte helpers *)
val #"a"   = Hex.toHexDigit 10
val SOME 15 = Hex.fromHexDigit #"F"
val NONE    = Hex.fromHexDigit #"g"
val "de"    = Hex.byteToHex (Word8.fromInt 0xDE)

(* tolerant decode: ignores whitespace and an optional 0x/0X prefix *)
val SOME _ = Hex.decodeLoose "de ad\nbe ef"   (* = decode "deadbeef" *)
val SOME _ = Hex.decodeLoose "0xDEAD"
val NONE   = Hex.decodeLoose "abc"            (* still strict on length/digits *)

(* xxd-style hexdump *)
print (Hex.hexdumpString "hello")
(* 00000000  68 65 6c 6c 6f                                    |hello| *)
```

## API summary

| Function | Description |
| --- | --- |
| `encode : Word8Vector.vector -> string` | Bytes to lowercase hex. |
| `encodeUpper : Word8Vector.vector -> string` | Bytes to uppercase hex. |
| `decode : string -> Word8Vector.vector option` | Hex to bytes; `NONE` if malformed. |
| `encodeString : string -> string` | Encode the bytes of a string (lowercase). |
| `decodeString : string -> string option` | Decode to a string of bytes. |
| `toHexDigit : int -> char` | Nibble `0..15` to `'0'..'f'`; raises `Domain` otherwise. |
| `fromHexDigit : char -> int option` | Hex digit (any case) to value, or `NONE`. |
| `byteToHex : Word8.word -> string` | One byte to two lowercase hex digits. |
| `decodeLoose : string -> Word8Vector.vector option` | Decode ignoring whitespace and a leading `0x`/`0X`. |
| `hexdump : Word8Vector.vector -> string` | xxd-style dump: offset, 16 hex columns, ASCII gutter. |
| `hexdumpString : string -> string` | `hexdump` of a string's bytes. |

## Example

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
walks encode/decode round-trips, the string wrappers, digit helpers, tolerant
decoding, and a hexdump (output is byte-identical under MLton and Poly/ML):

```
Encoding bytes to hex:
  encode      = deadbeef
  encodeUpper = DEADBEEF

Decoding hex to bytes:
  decode "deadbeef"         -> deadbeef
  decode "abc" (odd length) -> NONE
  decode "zz" (bad digit)   -> NONE

String convenience wrappers:
  encodeString "ML"   = 4d4c
  decodeString "4d4c" = ML

Digit / byte helpers:
  toHexDigit 10      = a
  fromHexDigit #"F"  = 15
  byteToHex 0xDE     = de

Tolerant decodeLoose (whitespace + "0x" prefix):
  decodeLoose "0x DE AD\tBE EF" -> deadbeef

Hexdump:
00000000  53 74 61 6e 64 61 72 64  20 4d 4c 21              |Standard ML!|
```

## Scope and limitations

- `decodeLoose` strips only ASCII whitespace (space, tab, CR, LF) and a single
  leading `0x`/`0X`. It does **not** accept separators between bytes other than
  whitespace, comments, or `0x` prefixes mid-string.
- `hexdump` is fixed at 16 bytes per line with an 8-digit offset and a
  `|...|` ASCII gutter (non-printables shown as `.`). Width and grouping are not
  configurable, and it is a formatter only — there is no inverse parser for the
  dump format.
- All strict entry points (`encode`/`encodeUpper`/`decode`/`encodeString`/
  `decodeString`) are unchanged.

## License

MIT. See [LICENSE](LICENSE).
