using afIoc
using afBedSheet

class WebSocketHandler {
	
	@Inject private HttpRequest 	httpRequest
	@Inject private HttpResponse	httpResponse
//	@Inject private Registry 		reg
	
	new make(|This|in) { in(this) }
	
	Obj service(Uri wotever) {

//		ep:=reg.autobuild(Pod.find("afBedSheet").type("ErrPrinter"))
//		e:=ep->errToStr(Err())
//		Env.cur.err.printLine(e)

//		key := req.headers["Sec-WebSocket-Key"] + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
//		
//		digest := Buf().print(key).toDigest("SHA-1").toBase64
//		
//		res.setStatusCode(101)
//		res.headers["Upgrade"] = "websocket"
//		res.headers["Connection"] = "Upgrade"
//		res.headers["Sec-WebSocket-Accept"] = digest
		
		
		
		req	:= WsReqBsImpl(httpRequest)
		res	:= WsResBsImpl(httpResponse)
		
		try {
			ok 	:= WebSocketCore().handshake(req, res)
			if (!ok) return false
			
		} catch (WebSocketErr wsErr) {
			return false
		}
		
		httpResponse.disableGzip
		httpResponse.disableBuffering
		
		// flush the headers out to the client
		resOut 	:= res.out.flush
		reqIn 	:= req.in
		
		frame	:= Frame.readFrom(reqIn)
		
		Env.cur.err.printLine(frame.payload.readAllStr)
		
		Frame("Whoop Whoop!").in.pipe(resOut)
		resOut.flush
		
		return true
	}

	static Void main(Str[] args) {
		key:= "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"		
		out:=Buf().print(key).toDigest("SHA-1").toBase64
		Env.cur.err.printLine(out)
		
		3.times |i| { 
			Env.cur.err.printLine(i)
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

enum class CloseFrameStatusCode {
	// see http://tools.ietf.org/html/rfc6455#section-7.4
	// http://www.iana.org/assignments/websocket/websocket.xml
	close
}

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
