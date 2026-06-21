(* hex.sml

   Implementation of HEX.

   Encoding maps each byte to its high and low nibble, indexing a digit table.
   Decoding parses two digits per byte, returning NONE on any malformed input
   (odd length or a non-hex character). String variants bridge through `Byte`. *)

structure Hex :> HEX =
struct
  val lowerDigits = "0123456789abcdef"
  val upperDigits = "0123456789ABCDEF"

  fun encodeWith digits v =
      let
        fun nib n = String.sub (digits, n)
        fun byteChars b =
            let val hi = Word8.toInt (Word8.>> (b, 0w4))
                val lo = Word8.toInt (Word8.andb (b, 0wxF))
            in [nib hi, nib lo] end
        val chars = Word8Vector.foldr (fn (b, acc) => byteChars b @ acc) [] v
      in
        String.implode chars
      end

  fun encode v = encodeWith lowerDigits v
  fun encodeUpper v = encodeWith upperDigits v

  (* digit value of a hex char, or NONE *)
  fun digitVal c =
      if c >= #"0" andalso c <= #"9" then SOME (Char.ord c - Char.ord #"0")
      else if c >= #"a" andalso c <= #"f" then SOME (Char.ord c - Char.ord #"a" + 10)
      else if c >= #"A" andalso c <= #"F" then SOME (Char.ord c - Char.ord #"A" + 10)
      else NONE

  fun decode s =
      let
        val n = String.size s
      in
        if n mod 2 <> 0 then NONE
        else
          let
            (* build bytes left-to-right; bail out (via exception) on bad char *)
            exception Bad
            fun byteAt i =
                case (digitVal (String.sub (s, 2 * i)),
                      digitVal (String.sub (s, 2 * i + 1))) of
                    (SOME hi, SOME lo) => Word8.fromInt (hi * 16 + lo)
                  | _ => raise Bad
          in
            SOME (Word8Vector.tabulate (n div 2, byteAt))
            handle Bad => NONE
          end
      end

  fun encodeString s = encode (Byte.stringToBytes s)

  fun decodeString s =
      case decode s of
          SOME v => SOME (Byte.bytesToString v)
        | NONE => NONE
end
