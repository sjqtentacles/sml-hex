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
  in
    Harness.run ()
  end
end
