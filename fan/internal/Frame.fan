
internal class Frame {
	FrameType	type
	Buf			payload
	Bool		fin
	Bool		maskFrame
	Bool		rsv1
	Bool		rsv2
	Bool		rsv3
	
	private new make(|This|in) {
		in(this)
	}
	
	new makeTextFrame(Str text) {
		this.type		= FrameType.text
		this.payload	= text.toBuf(Charset.utf8)
		this.fin		= true
		this.maskFrame	= false
	}

	new makePingFrame() {
		this.type		= FrameType.ping
		this.fin		= true
		this.payload	= Buf(0)
		this.maskFrame	= false
	}

	new makePongFrame() {
		this.type		= FrameType.pong
		this.fin		= true
		this.payload	= Buf(0)
		this.maskFrame	= false
	}

	new makeCloseFrame(Int? code, Str? reason) {
		this.type		= FrameType.close
		this.payload	= Buf((reason?.size ?: 0) + 2)
		this.fin		= true
		this.maskFrame	= false
		
		if (code != null) {
			payload.writeI2(code)
			if (reason != null) {
				payload.writeChars(reason)
			}
		}		
	}

	Frame fromClient() {
		this.maskFrame	= true
		return this
	}

	Str? payloadAsStr() {
		try {
			return (payload.remaining > 0) ? payload.in.readChars(payload.remaining) : null
		} catch (IOErr ioe) {
			throw CloseFrameErr(CloseCodes.invalidFramePayloadData, CloseMsgs.payloadNotStr)
		}
	}
	
	** Writes this frame to the given OutStream
	Void writeTo(OutStream out) {
		// TODO: catch IOErr should OutStream be closed and throw unclean CloseFrameErr
		byte		:= type.opCode
		if (fin)	byte = byte.or(0x80)
		if (rsv1)	byte = byte.or(0x40)
		if (rsv2)	byte = byte.or(0x20)
		if (rsv3)	byte = byte.or(0x10)

		out.write(byte)

		byte	= payload.size
		size2	:= (Int?) null
		size8	:= (Int?) null

		if (payload.size > 125) {
			byte	= 126
			size2	= payload.size 
		}
		if (payload.size > 2.pow(2*8)) {
			byte	= 127
			size2	= null 
			size8	= payload.size 
		}
		
		if (maskFrame)
			byte	= byte.or(0x80)
		out.write(byte)
		if (size2 != null)
			out.writeI2(size2)
		if (size8 != null)
			out.writeI2(size8)

		if (maskFrame) {
			maskBuf := Buf.random(4)
			out.writeBuf(maskBuf)
			payload.size.times |i| {
				j := maskBuf[i.mod(4)]
				out.write(payload[i].xor(j))
			}
		} else {
			payload.seek(0)
			out.writeBuf(payload)
		}
		
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
			// I know it's signed, but spec says "the most significant bit MUST be 0"
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