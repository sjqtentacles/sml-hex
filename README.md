# sml-hex

[![CI](https://github.com/sjqtentacles/sml-hex/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-hex/actions/workflows/ci.yml)

A small, portable hexadecimal encoder/decoder for Standard ML.

`sml-hex` converts between bytes and their hex-digit representation, with both
byte-oriented (`Word8Vector.vector`) and string-oriented entry points.
Decoding is strict -- it returns `NONE` on an odd number of digits or any
non-hex character -- but tolerant of mixed upper/lower case.

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
```

## API summary

| Function | Description |
| --- | --- |
| `encode : Word8Vector.vector -> string` | Bytes to lowercase hex. |
| `encodeUpper : Word8Vector.vector -> string` | Bytes to uppercase hex. |
| `decode : string -> Word8Vector.vector option` | Hex to bytes; `NONE` if malformed. |
| `encodeString : string -> string` | Encode the bytes of a string (lowercase). |
| `decodeString : string -> string option` | Decode to a string of bytes. |

## License

MIT. See [LICENSE](LICENSE).
