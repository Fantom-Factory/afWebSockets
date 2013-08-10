
internal class Frame {

	FrameType	type
	Buf			payload
	Bool		fin
	Bool		maskFrame
	
	new make(|This|in) {
		in(this)
	}
	
	new makeFromText(Str text) {
		this.type		= FrameType.text
		this.payload	= text.toBuf(Charset.utf8)
		this.fin		= true
		this.maskFrame	= false
	}

	new makeCloseFrame(Int code, Str reason) {
		this.type		= FrameType.close
		this.payload	= Buf().writeI2(code).writeUtf(reason)
		this.fin		= true
		this.maskFrame	= false
	}

	** Writes this frame to the given OutStream
	Void writeTo(OutStream out) {
		buf		:= Buf(payload.size + 14)	// 14 is the max no of extra frame bytes
		
		byte	:= type.opCode
		if (fin)
			byte = byte.or(0x80)

		buf.write(byte)

		// FIXME: to dat 126 / 127 thing!
		byte	= payload.size
		if (maskFrame)
			byte	= byte.or(0x80)
		buf.write(byte)	

		if (maskFrame) {
			maskBuf := Buf(4).writeI4(Int.random(0..<2.pow(32)))
			buf.writeBuf(maskBuf.flip)
			payload.size.times |i| {
				j := maskBuf[i.mod(4)]
				payload[i] = payload[i].xor(j)
			}
		}
		
		buf.writeBuf(payload)

		// write it out!
		buf.flip.in.pipe(out)
	}
	
	
	static new readFrom(InStream in) {
		byte	:= in.read
		
		if (byte == null)
			return null	// EOF
		
		fin		:= byte.and(0x80) > 0
//		rsv1	:= byte.and(0x40) > 0	// TODO: rsv's are used in extensions - MUST fail if no-ext and non-zero
//		rsv2	:= byte.and(0x20) > 0
//		rsv3	:= byte.and(0x10) > 0
		opCode	:= byte.and(0x0F)
		
		byte	= in.read
		mask	:= byte.and(0x80) > 0
		length	:= byte.and(0x7F)
		
		if (length == 126)
			length = in.readU2
		if (length == 127) 
			// I know it's signed, but spec says "the most significant bit MUST be 0"
			length = in.readS8
		// TODO: Belts'n'braces - if (length < 0) then Err
		
		maskBuf := (Buf?) null
		if (mask)
			maskBuf = in.readBufFully(null, 4)
		
		payload := in.readBufFully(null, length)
		
		if (mask) {
			payload.size.times |i| { 				
				j := maskBuf[i.mod(4)]
				payload[i] = payload[i].xor(j)
			}
		}
		
		return Frame {
			it.type		= FrameType(opCode)
			it.payload	= payload
			it.maskFrame= mask
			it.fin		= fin
		}
	}
}

internal enum class FrameType {
	continuation(0), text(1), binary(2), close(8), ping(9), pong(10);
	
	const Int opCode
	
	private new make(Int opCode) {
		this.opCode = opCode
	}

	static new fromOpCode(Int opCode, Bool checked := true) {
		FrameType.vals.find { it.opCode == opCode} ?: (checked ? throw Err("Could not find ${FrameType#.name} for OpCode $opCode") : null)
	}
}