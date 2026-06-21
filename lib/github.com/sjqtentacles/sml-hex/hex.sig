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
end
