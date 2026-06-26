(* Test suite for the Hex structure, standardized on the shared
 * sml-test Harness. *)

structure Tests =
struct
  open Harness

  structure H = Hex

  fun bytes l = Word8Vector.fromList (map Word8.fromInt l)
  fun vecEq (a, b) =
      Word8Vector.length a = Word8Vector.length b
      andalso let fun same i = i >= Word8Vector.length a
                             orelse (Word8Vector.sub (a, i) = Word8Vector.sub (b, i)
                                     andalso same (i + 1))
              in same 0 end

  fun run () =
    let
    (* ---- encode known vectors ---- *)
    val () = check "encode empty" (H.encode (bytes []) = "")
    val () = check "encode 'abc' bytes" (H.encode (bytes [0x61, 0x62, 0x63]) = "616263")
    val () = check "encode deadbeef"
                   (H.encode (bytes [0xDE, 0xAD, 0xBE, 0xEF]) = "deadbeef")
    val () = check "encode single 0x00" (H.encode (bytes [0]) = "00")
    val () = check "encode single 0xFF" (H.encode (bytes [255]) = "ff")
    val () = check "encode 0x0F low nibble" (H.encode (bytes [15]) = "0f")
    val () = check "encode 0xF0 high nibble" (H.encode (bytes [240]) = "f0")

    (* ---- uppercase ---- *)
    val () = check "encodeUpper deadbeef"
                   (H.encodeUpper (bytes [0xDE, 0xAD, 0xBE, 0xEF]) = "DEADBEEF")
    val () = check "encodeUpper ff" (H.encodeUpper (bytes [255]) = "FF")

    (* ---- decode ---- *)
    val () = check "decode empty"
                   (case H.decode "" of SOME v => vecEq (v, bytes []) | NONE => false)
    val () = check "decode deadbeef"
                   (case H.decode "deadbeef" of
                        SOME v => vecEq (v, bytes [0xDE, 0xAD, 0xBE, 0xEF]) | NONE => false)
    val () = check "decode uppercase"
                   (case H.decode "DEADBEEF" of
                        SOME v => vecEq (v, bytes [0xDE, 0xAD, 0xBE, 0xEF]) | NONE => false)
    val () = check "decode mixed case"
                   (case H.decode "DeAdBeEf" of
                        SOME v => vecEq (v, bytes [0xDE, 0xAD, 0xBE, 0xEF]) | NONE => false)

    (* ---- decode rejects malformed ---- *)
    val () = check "decode odd length is NONE" (H.decode "abc" = NONE)
    val () = check "decode single char is NONE" (H.decode "a" = NONE)
    val () = check "decode non-hex char is NONE" (H.decode "zz" = NONE)
    val () = check "decode embedded bad char is NONE" (H.decode "00gg00" = NONE)
    val () = check "decode space is NONE" (H.decode "00 11" = NONE)

    (* ---- round-trip property over all single bytes ---- *)
    fun roundtripByte b =
        case H.decode (H.encode (bytes [b])) of
            SOME v => vecEq (v, bytes [b])
          | NONE => false
    val allBytesOk =
        let fun loop i = i > 255 orelse (roundtripByte i andalso loop (i + 1))
        in loop 0 end
    val () = check "round-trip every byte value 0..255" allBytesOk

    (* round-trip a multi-byte vector *)
    val big = bytes [0, 1, 127, 128, 200, 255, 16, 15]
    val () = check "round-trip multi-byte vector"
                   (case H.decode (H.encode big) of
                        SOME v => vecEq (v, big) | NONE => false)
    val () = check "uppercase round-trip"
                   (case H.decode (H.encodeUpper big) of
                        SOME v => vecEq (v, big) | NONE => false)

    (* ---- string entry points ---- *)
    val () = check "encodeString 'abc'" (H.encodeString "abc" = "616263")
    val () = check "encodeString empty" (H.encodeString "" = "")
    val () = check "decodeString round-trip"
                   (H.decodeString (H.encodeString "Hello, world!") = SOME "Hello, world!")
    val () = check "decodeString malformed is NONE" (H.decodeString "xyz" = NONE)
    val () = check "encodeString known"
                   (H.encodeString "ML" = "4d4c")

    (* ---- digit / byte helpers ---- *)
    val () = check "toHexDigit 0" (H.toHexDigit 0 = #"0")
    val () = check "toHexDigit 10" (H.toHexDigit 10 = #"a")
    val () = check "toHexDigit 15" (H.toHexDigit 15 = #"f")
    val () = checkRaises "toHexDigit 16 raises Domain"
                   (fn () => H.toHexDigit 16)
    val () = checkRaises "toHexDigit ~1 raises Domain"
                   (fn () => H.toHexDigit ~1)
    val () = check "fromHexDigit '0'" (H.fromHexDigit #"0" = SOME 0)
    val () = check "fromHexDigit 'a'" (H.fromHexDigit #"a" = SOME 10)
    val () = check "fromHexDigit 'F'" (H.fromHexDigit #"F" = SOME 15)
    val () = check "fromHexDigit 'g' is NONE" (H.fromHexDigit #"g" = NONE)
    val () = check "byteToHex 0x00" (H.byteToHex (Word8.fromInt 0) = "00")
    val () = check "byteToHex 0xDE" (H.byteToHex (Word8.fromInt 0xDE) = "de")
    val () = check "byteToHex 0xFF" (H.byteToHex (Word8.fromInt 255) = "ff")

    (* ---- tolerant decode ---- *)
    val () = check "decodeLoose strips spaces"
                   (H.decodeLoose "de ad be ef" = H.decode "deadbeef")
    val () = check "decodeLoose strips mixed whitespace"
                   (H.decodeLoose "de ad\nbe\tef" = H.decode "deadbeef")
    val () = check "decodeLoose strips 0x prefix"
                   (H.decodeLoose "0xDEAD" = H.decode "DEAD")
    val () = check "decodeLoose strips 0X prefix"
                   (H.decodeLoose "0Xdead" = H.decode "dead")
    val () = check "decodeLoose 0x with internal spaces"
                   (H.decodeLoose "0x DE AD" = H.decode "DEAD")
    val () = check "decodeLoose still NONE on odd length"
                   (H.decodeLoose "abc" = NONE)
    val () = check "decodeLoose still NONE on bad digit"
                   (H.decodeLoose "zz" = NONE)
    val () = check "decodeLoose empty"
                   (case H.decodeLoose "  \n " of SOME v => vecEq (v, bytes []) | NONE => false)

    (* ---- hexdump ---- *)
    val dump = H.hexdumpString "hello"
    val () = check "hexdump has offset 00000000"
                   (String.isSubstring "00000000" dump)
    val () = check "hexdump has hex bytes"
                   (String.isSubstring "68 65 6c 6c 6f" dump)
    val () = check "hexdump has ascii gutter"
                   (String.isSubstring "|hello|" dump)
    val () = check "hexdump empty is \"\""
                   (H.hexdump (bytes []) = "")
    (* non-printables render as '.' in the gutter *)
    val ctrlDump = H.hexdump (bytes [0x00, 0x41, 0x7f])
    val () = check "hexdump non-printable as dot"
                   (String.isSubstring "|.A.|" ctrlDump)
    (* a full 16-byte line plus a partial second line *)
    val seventeen = bytes (List.tabulate (17, fn i => i))
    val bigDump = H.hexdumpString (Byte.bytesToString seventeen)
    val () = check "hexdump second line offset 00000010"
                   (String.isSubstring "00000010" bigDump)
  in
    Harness.run ()
  end
end
