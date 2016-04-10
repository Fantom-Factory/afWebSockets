#WebSockets v0.1.0
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v0.1.0](http://img.shields.io/badge/pod-v0.1.0-yellow.svg)](http://www.fantomfactory.org/pods/afWebSockets)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

WebSockets is a Fantom implementation of the [W3C WebSocket API](http://www.w3.org/TR/websockets/) and adheres to [RFC 6455](http://tools.ietf.org/html/rfc6455).

The same `WebSocket` class may be used as a Fantom desktop client, a Javascript web client, or from a web server.

WebSockets does not currently support frame fragmentation or continuations.

## Install

Install `WebSockets` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://pods.fantomfactory.org/fanr/ afWebSockets

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afWebSockets 0.1"]

## Documentation

Full API & fandocs are available on the [Fantom Pod Repository](http://pods.fantomfactory.org/pods/afWebSockets/).

## Quick Start

This example is a simple instant messaging application called *Chatbox!*

It has a basic client that, using the same Fantom code, runs in a browser and as a desktop application. A BedSheet web application is used to service the WebSockets and serve the Chatbox web client.

Due to the web client being Javascript compiled from Fantom code, Chatbox must first be compiled to a pod. All the interesting WebSocket code is in the `ChatboxRoutes` and `ChatboxClient` classes.

1. Create a text file called `Chatbox.fan`

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
                    BedSheetBuilder(AppModule#.qname).startWisp(8069)
                if (args.first == "-build")
                    Builder().main
            }
        }
        
        const class AppModule {
            @Contribute { serviceType=Routes# }
            Void contributeRoutes(Configuration conf) {
                conf.add(Route(`/`,     ChatboxRoutes#indexPage))
                conf.add(Route(`/ws`,   ChatboxRoutes#serviceWebSocket))
            }
        }
        
        const class ChatboxRoutes {
            @Inject private const WebSockets    webSockets
            @Inject private const HtmlInjector  htmlInjector
        
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
                            center  = convBox
                            bottom  = EdgePane {
                                center  = textBox
                                right   = Button { text = "Send"; onAction.add(sendMsg) }
                            }
                        },
                    },
                }
        
                // Desktop only code
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
                    "sys          1.0",
                    "fwt          1.0",
                    "web          1.0",
                    "build        1.0",
                    "concurrent   1.0",
                    "afIoc        2.0",
                    "afConcurrent 1.0",
                    "afBedSheet   1.4",
                    "afDuvet      1.0",
                    "afWebSockets 0+",
                ]
        
                srcDirs = [`Chatbox.fan`]
            }
        }


2. Compile the script to create a `wsChatbox` pod, the warnings are expected and may be ignored.

        C:\> fan Chatbox.fan -build
        
        WARN: Type 'afConcurrent::Synchronized' not available in Js
        WARN: Unknown build option -build
        compile [wsChatbox]
          Compile [wsChatbox]
            FindSourceFiles [1 files]
            CompileJs
            WritePod [file:/C:/Apps/Fantom/fan/lib/fan/wsChatbox.pod]
        BUILD SUCCESS [237ms]!


3. Start the Chatbox server:

        C:\> fan wsChatbox -server
        
        [info] [afBedSheet] Found mod 'wsChatbox::AppModule'
        [info] [afIoc] Adding module definitions from pod 'wsChatbox'
        [info] [afIoc] Adding module definition for wsChatbox::AppModule
        [info] [afIoc] Adding module definition for afBedSheet::BedSheetModule
        [info] [afIoc] Adding module definition for afIocConfig::ConfigModule
        [info] [afIoc] Adding module definition for afBedSheet::BedSheetEnvModule
        [info] [afIoc] Adding module definition for afIocEnv::IocEnvModule
        [info] [afIoc] Adding module definition for afDuvet::DuvetModule
        [info] [afIoc] Adding module definition for afWebSockets::WebSocketsModule
        [info] [afBedSheet] Starting Bed App 'ChatBox - A WebSocket Demo' on port 8069
        [info] [web] http started on port 8069
        [info] [afIocEnv] Setting from environment variable 'env' : development
        
        Duvet is configured with 10 RequireJS modules:
        
          afConcurrent : /pods/afConcurrent/afConcurrent
               afDuvet : /pods/afDuvet/afDuvet
          afWebSockets : /pods/afWebSockets/afWebSockets
            concurrent : /pods/concurrent/concurrent
                   fwt : /pods/fwt/fwt
                   gfx : /pods/gfx/gfx
                   sys : /pods/sys/sys
                  util : /pods/util/util
                   web : /pods/web/web
             wsChatbox : /pods/wsChatbox/wsChatbox
        
        48 IoC Services:
          10 Builtin
          27 Defined
           0 Proxied
          11 Created
        
        56.25% of services are unrealised (27/48)
           ___    __                 _____        _
          / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
         / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
        /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                 Alien-Factory BedSheet v1.4.14, IoC v2.0.10 /___/
        
        IoC Registry built in 200ms and started up in 78ms
        
        Bed App 'ChatBox - A WebSocket Demo' listening on http://localhost:8069/


4. Visit `http://localhost:8069/` to load a Chatbox web client:

  ![Chatbox Web Client](http://pods.fantomfactory.org/pods/afWebSockets/doc/chatbox-webClient.png)



  You may also start a Chatbox desktop client:



        C:\> fan wsChatbox -client



  ![Chatbox Desktop Client](http://pods.fantomfactory.org/pods/afWebSockets/doc/chatbox-desktopClient.png)



Messages are sent to the server, which then broadcasts it back out all connected clients. Instant messaging!

## Usage

The [WebSocket](http://pods.fantomfactory.org/pods/afWebSockets/api/WebSocket) class adheres to the [W3C WebSocket API](http://www.w3.org/TR/websockets/) and may be used as a client, or on the server, and even from Javascript. It has hooks that allow you to respond to various WebSocket events:

- [onOpen](http://pods.fantomfactory.org/pods/afWebSockets/api/WebSocket.onOpen)
- [onMessage](http://pods.fantomfactory.org/pods/afWebSockets/api/WebSocket.onMessage)
- [onError](http://pods.fantomfactory.org/pods/afWebSockets/api/WebSocket.onError)
- [onClose](http://pods.fantomfactory.org/pods/afWebSockets/api/WebSocket.onClose)

### Fantom Client

To create a Fantom WebSocket client:

```
webSock := WebSocket()
webSock.onMessage |MsgEvent e| { ... }
webSock.open(`ws:localhost:8069`)

// block in an event loop until the socket is closed
webSock.read
```

Note that `WebSocket.read()` enters a read event loop that blocks the current thread / Actor until the WebSocket is closed. Therefore it may be advantageous to call the `read()` method in an asynchronous fashion. Alien-Factory's [Concurrent](http://pods.fantomfactory.org/pods/afConcurrent) library is the easiest way to do this:

```
using afConcurrent::Synchronized

// call the blocking read() method in a background thread
safeSock := Unsafe(webSock)
Synchronized(ActorPool()).async |->| {
    safeSock.val->read
}
```

### Javascript Client

To create a Javascript WebSocket client:

```
webSock := WebSocket()
webSock.onMessage |MsgEvent e| { ... }
webSock.open(`ws:localhost:8069`)
```

Note that due to the asynchronous of Javascript, there is no need to call the `read()` method.

### BedSheet Server

To use in a BedSheet web application to service HTTP requests, simply create a `Route` handler that returns a WebSocket instance:

```
using afWebSockets

const class WsRoutes {
    WebSocket serviceWs() {
        webSock := WebSocket()
        webSock.onMessage |MsgEvent e| { ... }
        return webSock
    }
}
```

The instance will be saved in the `WebSockets` service so messages may be sent to the client at any time.

```
@Inject private const WebSockets webSockets

...
Void sayHello(Uri webSockId) {
    webSockets[webSockId].sendText("Hello Pips!")
}
```

The `WebSocket` instance will be automatically disposed of when the connection is closed, either by the client or server.

### WebMod Server

To use in a WebMod, the `WebSocket` instance needs to be upgraded manually:

```
using afWebSockets

const class WsWebMod : WebMod {

    Void serviceWs() {
        webSock := WebSocket()
        webSock.onMessage |MsgEvent e| { ... }
        webSock.upgrade(req, res)
        webSock.read
    }
}
```

Or you could store in a `WebSockets` instance:

```
using afWebSockets
using web

const class WsWebMod : WebMod {
    const WebSockets webSockets := WebSockets(ActorPool())

    Void serviceWs() {
        webSock := WebSocket()
        webSock.onMessage |MsgEvent e| { ... }
        webSockets.service(webSock, req, res)
    }

    override Void onStop() {
        webSockets.shutdown
    }
}
```

