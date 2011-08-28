###
A little client for testing the IRC librarry
###

requirejs = require 'requirejs'
net = require 'net'
requirejs.config
	nodeRequire: require
	
ConnectIRC = (client, server, port = 6667) ->
	process.stdin.resume()
	process.stdin.setEncoding('utf8')
	
	socket = new net.Socket
		type: 'tcp6'
	socket.setEncoding 'utf8'
	
	client.on 'log', console.log
	client.on 'send', (str) ->
		socket.write(str + "\r\n")
		console.log("-->" + str)
	socket.on 'error', (error) ->
		console.error "Error connecting to "+server+"\n"+error.message
	socket.on 'connect', ->
		console.log "Connected to "+server+":"+port
		client.start()
		
	socket.on 'data', (data)->
		lines = data.split("\n")
		for line in lines
			console.log("<--", line)
			client.recv(line)
	process.stdin.on 'data', (line)->
		console.log("Line!")		
	
	#socket.connect(port, server)
	
	return [client, socket]

requirejs ['irc'], (irc)->
	#IRC module loaded, let's roll!
	client = new irc.Client
		nick: "JoeBot_3004"
		ident: "joebot3004"
		realname: "Joe Bot"
	ConnectIRC(client, 'irc.freenode.net')
