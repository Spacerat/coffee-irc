net = require 'net'

exports.setup = (m, e) ->
		
	m.hook 'socket', (irc, server, port, onconnect)->
		socket = new net.Socket
			type: 'tcp6'
		socket.setEncoding 'utf8'
		socket.on 'error', (error) ->
			console.error "Error connecting to "+server+"\n"+error.message
		socket.on 'connect', ->
			m.emit 'log', "Connected to "+server+":"+port
			irc.onRaw (str)->
				socket.write(str + "\r\n")
				m.emit('log', "--> #{str}")
			onconnect()
		
		linebuff = ''
		# Communcation with the server
		socket.on 'data', (data)->
			lines = data.split("\n")
			if (linebuff)
				lines[0] = linebuff+lines[0]
				linebuff = ''
			for line in lines
				if line.substr(-1) == "\r"
					line = line.trim()
					console.log("<--", line)
					irc.recv(line)
				else
					linebuff = line
						
		# Connect to the server
		socket.connect(port, server)
	
