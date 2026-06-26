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

  (* --- digit / byte helpers --- *)

  fun toHexDigit n =
      if n >= 0 andalso n <= 15 then String.sub (lowerDigits, n)
      else raise Domain

  fun fromHexDigit c = digitVal c

  fun byteToHex b =
      let val hi = Word8.toInt (Word8.>> (b, 0w4))
          val lo = Word8.toInt (Word8.andb (b, 0wxF))
      in String.implode [toHexDigit hi, toHexDigit lo] end

  (* --- tolerant decode --- *)

  fun decodeLoose s =
      let
        fun isWs c = c = #" " orelse c = #"\t" orelse c = #"\n" orelse c = #"\r"
        val noWs = String.implode (List.filter (fn c => not (isWs c))
                                                (String.explode s))
        val stripped =
            if String.isPrefix "0x" noWs orelse String.isPrefix "0X" noWs
            then String.extract (noWs, 2, NONE)
            else noWs
      in
        decode stripped
      end

  (* --- hexdump (xxd-style) --- *)

  fun hexdump v =
      let
        val n = Word8Vector.length v
        fun byte i = Word8.toInt (Word8Vector.sub (v, i))
        (* 8-digit zero-padded hex offset *)
        fun offset i =
            let
              fun go (x, acc, k) =
                  if k = 0 then acc
                  else go (x div 16, String.str (toHexDigit (x mod 16)) ^ acc, k - 1)
            in go (i, "", 8) end
        (* one line covering [base, base+16) *)
        fun line base =
            let
              val cols =
                  List.tabulate (16, fn j =>
                    let val i = base + j in
                      if i < n then byteToHex (Word8Vector.sub (v, i)) else "  "
                    end)
              (* group into two 8-byte halves separated by an extra space *)
              val left = String.concatWith " " (List.take (cols, 8))
              val right = String.concatWith " " (List.drop (cols, 8))
              val hexPart = left ^ "  " ^ right
              val gutter =
                  String.implode (List.tabulate (Int.min (16, n - base), fn j =>
                    let val c = byte (base + j) in
                      if c >= 32 andalso c < 127 then Char.chr c else #"."
                    end))
            in
              offset base ^ "  " ^ hexPart ^ "  |" ^ gutter ^ "|"
            end
        fun loop base acc =
            if base >= n then List.rev acc
            else loop (base + 16) (line base :: acc)
      in
        if n = 0 then "" else String.concatWith "\n" (loop 0 []) ^ "\n"
      end

  fun hexdumpString s = hexdump (Byte.stringToBytes s)
end
