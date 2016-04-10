    using afWebSockets
    using afIoc
    using afBedSheet
    using afBedSheet::Text as BsText
    using afConcurrent::Synchronized
    using afDuvet::DuvetModule
    using afDuvet::HtmlInjector
    using concurrent::ActorPool
    using fwt
    using build::BuildPod
    
    class Main {	
    	Void main(Str[] args) {
    		if (args.first == "-client")
    			ChatboxClient().main
    		if (args.first == "-server")
    			BedSheetBuilder(AppModule#.qname).addModulesFromPod("afWebSockets").startWisp(8069)
    		if (args.first == "-build")
    			Builder().main
    	}
    }
    
    const class AppModule {
    	@Contribute { serviceType=Routes# }
    	Void contributeRoutes(Configuration conf) {
    		conf.add(Route(`/`, 	ChatboxRoutes#indexPage))
    		conf.add(Route(`/ws`,	ChatboxRoutes#serviceWebSocket))
    	}
    }
    
    const class ChatboxRoutes {
    	@Inject private const WebSockets	webSockets
    	@Inject private const HtmlInjector	htmlInjector
    	
    	new make(|This|in) { in(this) }
    
    	BsText indexPage() {
    		htmlInjector.injectFantomMethod(ChatboxClient#main)
    		return BsText.fromHtml(
    			"<!DOCTYPE html>
    			 <html>
    			 <head>
    			 	<title>ChatBox - A WebSocket Demo</title>
    			 </head>
    			 <body>
    			 </body>
    			 </html>")
    	}
    	
    	WebSocket serviceWebSocket() {
    		WebSocket.make() {
    			ws := it
    			onMessage = |MsgEvent me| { 
    				webSockets.broadcast("${ws.id} says, '${me.txt}'")
    			}
    		}
    	}
    }
    
    @Js
    class ChatboxClient {
    	Void main() {
    		webSock := WebSocket.make().open(`ws://localhost:8069/ws`)
    		convBox := Text { text = "The conversation:\r\n"; multiLine = true; editable = false }
    		textBox := Text { text = "Say something!" }
    		sendMsg := |Event e| {
    			webSock.sendText(textBox.text)
    			textBox.text = ""
    		}
    
    		webSock.onMessage = |MsgEvent msgEnv| {
    			convBox.text += "\r\n" + msgEnv.txt			
    		}
    
    		textBox.onAction.add(sendMsg)
    
    		window := Window {
    			title = "ChatBox - A WebSocket Demo"
    			InsetPane {
    				EdgePane {
    					center	= convBox
    					bottom	= EdgePane {
    						center	= textBox
    						right	= Button { text = "Send"; onAction.add(sendMsg) }
    					}
    				},
    			},
            }
    		
			// desktop only code
    		if (Env.cur.runtime != "js") {
    			// ensure event funcs are run in the UI thread
    			safeFunc := Unsafe(webSock.onMessage)
    			webSock.onMessage = |MsgEvent msgEnv| {
    				safeMess := Unsafe(msgEnv)
    				Desktop.callAsync |->| { safeFunc.val->call(safeMess.val) }
    			}
    
    			// call the blocking read() method in a background thread
    			safeSock := Unsafe(webSock)
    			Synchronized(ActorPool()).async |->| {
    				safeSock.val->read
    			}
    		}
    
    		window.open
    	}
    }
    
    class Builder : BuildPod {
        new make() {
            podName = "wsChatbox"
            summary = "A WebSocket Demo"
    
            meta = [
                "proj.name"    : "ChatBox - A WebSocket Demo",
                "afIoc.module" : "wsChatbox::AppModule",
            ]
    
            depends = [
                "sys          1.0.68 - 1.0",
                "fwt          1.0.68 - 1.0",
                "web          1.0.68 - 1.0",
                "build        1.0.68 - 1.0",
                "concurrent   1.0.68 - 1.0",
                "afIoc        3.0.0  - 3.0",
                "afConcurrent 1.0.0  - 1.0",
                "afBedSheet   1.5.0  - 1.5",
                "afDuvet      1.1.0  - 1.1",
                "afWebSockets 0.1.0  - 0.1",
            ]
    
            srcDirs = [`Chatbox.fan`]
        }
    }	

