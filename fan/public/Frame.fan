
class Frame {

	FrameType		type
	Buf				payload

	private Bool	fin
	private Bool	maskFrame
	
	new make(|This|in) {
		in(this)
	}
	
	new makeFromText(Str text, Charset charset := Charset.utf8) {
		this.type		= FrameType.text
		this.payload	= text.toBuf(charset)
		this.fin		= true
	}

	InStream in() {
		buf		:= Buf(payload.size + 14)	// 14 is the max no of extra frame bytes
		
		byte	:= type.opCode
		if (fin)
			byte = byte.or(0x80)

		buf.write(byte)
		
		// FIXME: or with Mask bit
		buf.write(payload.size)	// FIXME: to dat 126 / 127 thing!
		
		// FIXME: mask data
		
		buf.writeBuf(payload)
		
		
		
		return buf.flip.in
	}
	
	
	static new readFrom(InStream in) {
		byte	:= in.read	// TODO: does this block?
		
		fin		:= byte.and(0x80) > 0
//		rsv1	:= byte.and(0x40) > 0	// TODO: rsv's are used in extensions - MUST fail if no-ext and non-zero
//		rsv2	:= byte.and(0x20) > 0
//		rsv3	:= byte.and(0x10) > 0
		opCode	:= byte.and(0x0F)
		
		byte	= in.read	// TODO: does this block?
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
		}
	}
}

enum class FrameType {
	continuation(0), text(1), binary(2), close(8), ping(9), pong(10);
	
	const Int opCode
	
	private new make(Int opCode) {
		this.opCode = opCode
	}

	static new fromOpCode(Int opCode, Bool checked := true) {
		FrameType.vals.find { it.opCode == opCode} ?: (checked ? throw Err("Could not find ${FrameType#.name} for OpCode $opCode") : null)
	}
}