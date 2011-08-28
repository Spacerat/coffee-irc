define -> (irc, hook) ->
	hook '#PING', (message) ->
		irc.S('PONG %s', message.text)
	return this
