exports.module = (hook, m) ->
	# Connected to the server
	hook '#001', (irc, message) ->
		irc.emit('connected')
	
	# Nick taken
	hook '#433', (irc, message) ->
		if (nick = irc.nextNick()) == null
			if not irc.emit('no_nick')
				irc.disconnect()
		irc.S("NICK %s", nick)

	# Recieved private message
	hook '#PRIVMSG', (irc, message) ->
		from = message.args[1]
		if from[0] == '#' and (channel = irc.channels?[from])
			type = 'Channel'
		data = {
			text: message.text
			type: type
			channel: channel
			nick: message.nick
			reply: (message, args...) ->
				irc.S("PRIVMSG %s :#{message}", from, args...)
		}
		irc.emit('message', message.text, data)

	# /msg <destination> <message>
	hook '/msg', (irc, c) ->
		irc.S('PRIVMSG '+c.text)
		
	# /loadmodule <name> <name>...
	hook '/load', (irc, c)->
		m.load_module(name, irc) for name in c.text.split(" ")
	hook '/unload', (irc, c)->
		m.unload_module(name, irc) for name in c.text.split(" ")
	hook '/reload', (irc, c)->
		m.unload_module(name, irc) for name in c.text.split(" ")
		m.load_module(name, irc) for name in c.text.split(" ")
	return this
