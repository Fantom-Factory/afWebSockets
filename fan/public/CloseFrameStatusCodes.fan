
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
const class CloseFrameStatusCodes {
	
	** Indicates a normal closure, meaning that the purpose for which the connection was 
	** established has been fulfilled.
	const Int normalClosure				:= 1000
	
	** Indicates that an endpoint is "going away", such as a server going down or a browser having 
	** navigated away from a page.
	const Int goingAway					:= 1001
	
	** Indicates that an endpoint is terminating the connection due to a protocol error.
	const Int protocolError				:= 1002
	
	** Indicates that an endpoint is terminating the connection because it has received a type of 
	** data it cannot accept (e.g., an endpoint that understands only text data MAY send this if it 
	** receives a binary message).
	const Int unsupportedData			:= 1003
	
	** Reserved. The specific meaning might be defined in the future.
	const Int reserved					:= 1004
	
	** Reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. 
	** It is designated for use in applications expecting a status code to indicate that no status 
	** code was actually present.
	const Int noStatusRcvd				:= 1005
	
	** Reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. 
	** It is designated for use in applications expecting a status code to indicate that the 
	** connection was closed abnormally, e.g., without sending or receiving a Close control frame.
	const Int abnormalClosure			:= 1006
	
	** Indicates that an endpoint is terminating the connection because it has received data within 
	** a message that was not consistent with the type of the message (e.g., non-UTF-8 [RFC3629] 
	** data within a text message).
	const Int invalidFramePayloadData	:= 1007
	
	** Indicates that an endpoint is terminating the connection because it has received a message 
	** that violates its policy. This is a generic status code that can be returned when there is 
	** no other more suitable status code (e.g., 1003 or 1009) or if there is a need to hide 
	** specific details about the policy.
	const Int policyViolation			:= 1008
	
	** Indicates that an endpoint is terminating the connection because it has received a message 
	** that is too big for it to process.
	const Int messageTooBig				:= 1009
	
	** Indicates that an endpoint (client) is terminating the connection because it has expected 
	** the server to negotiate one or more extension, but the server didn't return them in the 
	** response message of the WebSocket handshake.  The list of extensions that are needed SHOULD 
	** appear in the /reason/ part of the Close frame. Note that this status code is not used by 
	** the server, because it can fail the WebSocket handshake instead.
	const Int mandatoryExt				:= 1010
	
	** Indicates that a server is terminating the connection because it encountered an unexpected 
	** condition that prevented it from fulfilling the request.
	const Int internalError				:= 1011

	** Indicates that the service is restarting. a client may reconnect, and if it chooses to do 
	** so, should reconnect using a randomised delay of 5 -30s.
	const Int serviceRestart			:= 1012
	
	** Indicates that the service is unable to process to the request (dur to service overload or 
	** similar) and the client should try again later.
	const Int tryAgainLater				:= 1013
	
	** Unassigned.
	const Int unassigned				:= 1014
	
	** Reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. 
	** It is designated for use in applications expecting a status code to indicate that the 
	** connection was closed due to a failure to perform a TLS handshake (e.g., the server 
	** certificate can't be verified).
	const Int tlsHandshake				:= 1015

}
