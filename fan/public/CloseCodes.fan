
** Pre-defined status codes of Close frames.
** 
** 0-999:
** Not used.
** 
** 1000-2999:
** Reserved for definition by this protocol, its future revisions, and extensions specified in a 
** permanent and readily available public specification.
** 
** 3000-3999:
** Reserved for use by libraries, frameworks, and applications. These status codes are registered 
** directly with IANA. The interpretation of these codes is undefined by this protocol.
** 
** 4000-4999:
** Reserved for private use and thus can't be registered. Such codes can be used by prior 
** agreements between WebSocket applications. The interpretation of these codes is undefined by 
** this protocol.
** 
** @see 
** - http://tools.ietf.org/html/rfc6455#section-7.4
** - http://www.iana.org/assignments/websocket/websocket.xml#close-code-number
** 
// TODO: turn into const class with msgs - doc that it can't be enum 'cos any code is valid - only keep the ones we actually use - don't forget to impl equals
// TODO: actually - don't!!!! Keep this internal
internal const mixin CloseCodes {
	
	** Indicates a normal closure, meaning that the purpose for which the connection was 
	** established has been fulfilled.
	static const Int normalClosure				:= 1000
	
	** Indicates that an endpoint is "going away", such as a server going down or a browser having 
	** navigated away from a page.
	static const Int goingAway					:= 1001
	
	** Indicates that an endpoint is terminating the connection due to a protocol error.
	static const Int protocolError				:= 1002
	
	** Indicates that an endpoint is terminating the connection because it has received a type of 
	** data it cannot accept (e.g., an endpoint that understands only text data MAY send this if it 
	** receives a binary message).
	static const Int unsupportedData			:= 1003
	
	** Reserved. The specific meaning might be defined in the future.
	static const Int reserved					:= 1004
	
	** Reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. 
	** It is designated for use in applications expecting a status code to indicate that no status 
	** code was actually present.
	static const Int noStatusRcvd				:= 1005
	
	** Reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. 
	** It is designated for use in applications expecting a status code to indicate that the 
	** connection was closed abnormally, e.g., without sending or receiving a Close control frame.
	static const Int abnormalClosure			:= 1006
	
	** Indicates that an endpoint is terminating the connection because it has received data within 
	** a message that was not consistent with the type of the message (e.g., non-UTF-8 [RFC3629] 
	** data within a text message).
	static const Int invalidFramePayloadData	:= 1007
	
	** Indicates that an endpoint is terminating the connection because it has received a message 
	** that violates its policy. This is a generic status code that can be returned when there is 
	** no other more suitable status code (e.g., 1003 or 1009) or if there is a need to hide 
	** specific details about the policy.
	static const Int policyViolation			:= 1008
	
	** Indicates that an endpoint is terminating the connection because it has received a message 
	** that is too big for it to process.
	static const Int messageTooBig				:= 1009
	
	** Indicates that an endpoint (client) is terminating the connection because it has expected 
	** the server to negotiate one or more extension, but the server didn't return them in the 
	** response message of the WebSocket handshake.  The list of extensions that are needed SHOULD 
	** appear in the /reason/ part of the Close frame. Note that this status code is not used by 
	** the server, because it can fail the WebSocket handshake instead.
	static const Int mandatoryExt				:= 1010
	
	** Indicates that a server is terminating the connection because it encountered an unexpected 
	** condition that prevented it from fulfilling the request.
	static const Int internalError				:= 1011

	** Indicates that the service is restarting. a client may reconnect, and if it chooses to do 
	** so, should reconnect using a randomised delay of 5 -30s.
	static const Int serviceRestart				:= 1012
	
	** Indicates that the service is unable to process to the request (dur to service overload or 
	** similar) and the client should try again later.
	static const Int tryAgainLater				:= 1013
	
	** Unassigned.
	static const Int unassigned					:= 1014
	
	** Reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. 
	** It is designated for use in applications expecting a status code to indicate that the 
	** connection was closed due to a failure to perform a TLS handshake (e.g., the server 
	** certificate can't be verified).
	static const Int tlsHandshake				:= 1015

}

internal mixin CloseMsgs {
	
	static const Str normalClosure				:= "Normal Closure"
	static const Str frameNotMasked				:= "Protocol Error: Frame payload not masked"
	static const Str payloadNotStr				:= "Invalid Frame Payload Data: Frame payload contained invalid UTF data"
	static const Str abnormalClosure			:= "Abnormal Closure: No close control frame received"
	
	static Str frameInvalidLength(Int length)		{ "Protocol Error: Frame payload length must be positive: ${length}"	}
	static Str unsupportedFrame(FrameType type)		{ "Unsupported Data: Frame type ${type} not supported"					}
	static Str unsupportedOpCode(Int type)			{ "Unsupported Data: OpCode ${type} not supported"						}
	static Str internalError(Err err)				{ "Internal Error: ${err.typeof.qname} - ${err.msg}"					}

}
