modules = require('./modules')

config = require('./config.js').config

modules.load_module(mod) for mod in config.modules

modules.modules['irc-core'].IRC(config).start()

###
ConnectIRC = (client, server, port = 6667) ->
	# Here we patch the client to our new socket and stdin for input, and stdio for output
	# We also set up the "interface"
	stdin_channel = null
	
	# Set up connections
	process.stdin.resume()
	process.stdin.setEncoding('utf8')	
	
	socket = new net.Socket
		type: 'tcp6'
	socket.setEncoding 'utf8'
	
	socket.on 'error', (error) ->
		console.error "Error connecting to "+server+"\n"+error.message
	socket.on 'connect', ->
		console.log "Connected to "+server+":"+port
		client.start()
		
	# Communcation with the server
	socket.on 'data', (data)->
		lines = data.split("\n")
		for line in lines
			line = line.trim()
			if line
				console.log("<--", line)
				client.recv(line)
			
	client.on 'send', (str) ->
		socket.write(str + "\r\n")
		console.log("-->" + str)
	# Communication with the client
	client.on 'log', console.log
	process.stdin.on 'data', (line)->
		if not client.input(line)
			stdin_channel.say(line.trim()) if stdin_channel?
		
	# Connect to the server
	socket.connect(port, server)
	
	# Make chat possible
	client.on 'join', (channel) ->
		console.log "Joined channel #{channel.name}"
		stdin_channel = channel
	client.on 'topic', (channel) ->
		console.log "Set topic of #{channel.name} to #{channel.topic}"
	client.on 'names', (channel) ->
		console.log "Users in #{channel.name}: "+channel.names.join(', ')
	client.on 'message', (text, data) ->
		console.log text
	client.on '#NOTICE', (m) ->
		console.log m.text
	
	client.onAny(modules.emit)
	
	modules.load_module(mod, client) for mod in config.modules
		
	return [client, socket]
###

#ConnectIRC(client, 'irc.freenode.net')

