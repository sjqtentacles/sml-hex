(* demo.sml - byte/hex round-tripping, decoding edge cases, and a hexdump.
   Deterministic: all input is literal, no clock, no randomness. *)

structure H = Hex

val () = print "Encoding bytes to hex:\n"
val bytes = Word8Vector.fromList [0wxDE, 0wxAD, 0wxBE, 0wxEF]
val () = print ("  encode      = " ^ H.encode bytes ^ "\n")
val () = print ("  encodeUpper = " ^ H.encodeUpper bytes ^ "\n")

val () = print "\nDecoding hex to bytes:\n"
val () = print ("  decode \"deadbeef\"         -> " ^ H.encode (valOf (H.decode "deadbeef")) ^ "\n")
val () = print ("  decode \"abc\" (odd length) -> "
                ^ (case H.decode "abc" of NONE => "NONE" | SOME _ => "SOME") ^ "\n")
val () = print ("  decode \"zz\" (bad digit)   -> "
                ^ (case H.decode "zz" of NONE => "NONE" | SOME _ => "SOME") ^ "\n")

val () = print "\nString convenience wrappers:\n"
val () = print ("  encodeString \"ML\"   = " ^ H.encodeString "ML" ^ "\n")
val () = print ("  decodeString \"4d4c\" = " ^ valOf (H.decodeString "4d4c") ^ "\n")

val () = print "\nDigit / byte helpers:\n"
val () = print ("  toHexDigit 10      = " ^ Char.toString (H.toHexDigit 10) ^ "\n")
val () = print ("  fromHexDigit #\"F\"  = "
                ^ (case H.fromHexDigit #"F" of SOME n => Int.toString n | NONE => "NONE") ^ "\n")
val () = print ("  byteToHex 0xDE     = " ^ H.byteToHex 0wxDE ^ "\n")

val () = print "\nTolerant decodeLoose (whitespace + \"0x\" prefix):\n"
val () = print ("  decodeLoose \"0x DE AD\\tBE EF\" -> "
                ^ H.encode (valOf (H.decodeLoose "0x DE AD\tBE EF")) ^ "\n")

val () = print "\nHexdump:\n"
val () = print (H.hexdump (Byte.stringToBytes "Standard ML!"))
