
internal class Frame {
	FrameType	type
	Buf			payload
	Bool		fin			:= true
	Bool		rsv1
	Bool		rsv2
	Bool		rsv3
	Bool		maskFrame	:= false
	
	private new make(|This|in) {
		in(this)
	}
	
	new makeTextFrame(Str txt) {
		this.type		= FrameType.text
		this.payload	= txt.toBuf(Charset.utf8)
	}
	
	new makeBinaryFrame(Buf bin) {
		this.type		= FrameType.binary
		this.payload	= bin.seek(0).readAllBuf
	}

	new makePingFrame() {
		this.type		= FrameType.ping
		this.payload	= Buf(0)
	}

	new makePongFrame() {
		this.type		= FrameType.pong
		this.payload	= Buf(0)
	}

	new makeCloseFrame(Int? code, Str? reason) {
		this.type		= FrameType.close
		this.payload	= Buf((reason?.size ?: 0) + 2)
		
		if (code != null) {
			payload.writeI2(code)
			if (reason != null) {
				payload.writeChars(reason)
			}
		}		
	}

	Frame fromClient(Bool isClient := true) {
		this.maskFrame = isClient
		return this
	}

	Str payloadAsStr() {
		try {
			return (payload.remaining > 0) ? payload.in.readChars(payload.remaining) : ""
		} catch (IOErr ioe) {
			throw CloseFrameErr(CloseCodes.invalidFramePayloadData, CloseMsgs.payloadNotStr)
		}
	}

	Buf payloadAsBuf() {
		buf := Buf(payload.remaining)
		if (payload.remaining > 0)
			payload.in.readBuf(buf, payload.remaining)
		return buf
	}
	
	** Writes this frame to the given OutStream
	Void writeTo(OutStream out) {
		byte		:= type.opCode
		
		if (fin)	byte = byte.or(0x80)
		if (rsv1)	byte = byte.or(0x40)
		if (rsv2)	byte = byte.or(0x20)
		if (rsv3)	byte = byte.or(0x10)
		out.write(byte)

		mask := maskFrame ? 0x80 : 0x00
		if (payload.size <= 125)
			out.write(payload.size.or(mask))
		else if (payload.size <= 0xFFFF)
			out.write(126.or(mask)).writeI2(payload.size)
		else
			out.write(127.or(mask)).writeI8(payload.size)
		
		if (maskFrame) {
			maskBuf := Buf.random(4)
			out.writeBuf(maskBuf)
			payload.size.times |i| {
				j := maskBuf[i.mod(4)]
				out.write(payload[i].xor(j))
			}
		} else
			out.writeBuf(payload.seek(0))
		
		// flush it down the pipe...
		out.flush
	}
	
	** Reads a frame from the given InStream
	static new readFrom(InStream in) {
		byte	:= in.read
		
		if (byte == null)
			return null	// EOF
		
		fin		:= byte.and(0x80) > 0
		rsv1	:= byte.and(0x40) > 0
		rsv2	:= byte.and(0x20) > 0
		rsv3	:= byte.and(0x10) > 0
		opCode	:= byte.and(0x0F)
		
		byte	= in.read
		mask	:= byte.and(0x80) > 0
		length	:= byte.and(0x7F)
		
		if (length == 126)
			length = in.readU2
		if (length == 127) 
			// I know readS8 is signed, but spec says "the most significant bit MUST be 0"
			length = in.readS8
		
		if (length < 0)
			throw CloseFrameErr(CloseCodes.protocolError, CloseMsgs.frameInvalidLength(length))
		
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
			it.rsv1		= rsv1
			it.rsv2		= rsv2
			it.rsv3		= rsv3
		}
	}
}

internal enum class FrameType {
	continuation(0), text(1), binary(2), close(8), ping(9), pong(10);
	
	const Int opCode
	
	private new make(Int opCode) {
		this.opCode = opCode
	}

	static new fromOpCode(Int opCode) {
		FrameType.vals.find { it.opCode == opCode} ?: throw CloseFrameErr(CloseCodes.unsupportedData, CloseMsgs.unsupportedOpCode(opCode))
	}
}
