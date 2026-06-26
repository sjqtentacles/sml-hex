(* hex.sig

   Hexadecimal encoding and decoding for Standard ML.

   Encoding turns bytes into a string of hex digits (two per byte); decoding is
   the inverse and is tolerant in exactly one way: it accepts both upper- and
   lower-case digits. Anything else -- an odd number of digits, or a non-hex
   character -- makes decoding return `NONE`.

   Both byte-oriented (`Word8Vector.vector`) and string-oriented entry points
   are provided. The string variants treat a string as its sequence of
   character bytes (via `Byte`), which is the common case for hashing/encoding
   ASCII or binary-in-a-string data. *)

signature HEX =
sig
  (* Encode bytes as lowercase hex (two digits per byte). *)
  val encode      : Word8Vector.vector -> string
  (* Encode bytes as uppercase hex. *)
  val encodeUpper : Word8Vector.vector -> string

  (* Decode a hex string to bytes. Returns NONE on odd length or any
     non-hex-digit character. Accepts mixed upper/lower case. *)
  val decode      : string -> Word8Vector.vector option

  (* Convenience: encode the bytes of a string (lowercase). *)
  val encodeString : string -> string
  (* Convenience: decode to a string of bytes. NONE on malformed input. *)
  val decodeString : string -> string option

  (* --- digit / byte helpers --- *)

  (* Map a nibble value 0..15 to its lowercase hex digit. Raises Domain for
     any value outside 0..15. *)
  val toHexDigit : int -> char
  (* Parse a single hex digit (upper or lower case) to its value, or NONE. *)
  val fromHexDigit : char -> int option
  (* Encode a single byte as two lowercase hex digits. *)
  val byteToHex : Word8.word -> string

  (* --- tolerant decode --- *)

  (* Like `decode`, but first strips ASCII whitespace (space, tab, CR, LF) and
     a single optional leading "0x"/"0X" prefix. Still returns NONE on an odd
     number of remaining digits or any non-hex character. *)
  val decodeLoose : string -> Word8Vector.vector option

  (* --- hexdump (xxd-style) --- *)

  (* Format bytes as a classic hexdump: 16 bytes per line, each line is
       OFFSET(8 hex)  <up to 16 space-separated hex bytes>  |ascii gutter|
     Non-printable bytes appear as '.' in the gutter. Returns "" for empty. *)
  val hexdump : Word8Vector.vector -> string
  (* Hexdump the bytes of a string. *)
  val hexdumpString : string -> string
end
