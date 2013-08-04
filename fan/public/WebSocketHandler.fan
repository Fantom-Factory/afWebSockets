using afIoc
using afBedSheet

class WebSocketHandler {
	
	@Inject private HttpRequest 	httpRequest
	@Inject private HttpResponse	httpResponse
	
	new make(|This|in) { in(this) }
	
	Obj service(Uri wotever) {
		
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

}


enum class CloseFrameStatusCode {
	// see http://tools.ietf.org/html/rfc6455#section-7.4
	// http://www.iana.org/assignments/websocket/websocket.xml
	close
}


