exports.module = (hook, m) ->

	@connect(server, port) ->
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
			
		hook 'send', (str, irc) ->
			socket.write(str + "\r\n")
			console.log("-->" + str)
		socket.connect(port, server)
		
		return [client, socket]

