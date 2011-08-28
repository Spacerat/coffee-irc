define -> (irc, hook) ->
	#Connected to the server
	hook '#001', (m) ->
		irc.emit('connected')
	
	#Nick taken
	hook '#443', (m) ->
		if (nick = irc.nextNick()) == null
			if not irc.emit('no_nick')
				irc.disconnect()
		irc.S("NICK %s", nick)

	hook '#PRIVMSG', (m) ->
		from = m.args[1]
		if from[0] == '#' and (channel = irc.m('channels')?.list[from])
			type = 'Channel'
		message = {
			text: m.text
			type: type
			channel: channel
			nick: m.nick
		}
		irc.emit('message', m.text, message)

	return this
