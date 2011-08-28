define -> (irc) -> # Two lines of boilerplate at the start, one at the end.
	@name = 'ping'
	irc.on 'cmd.PING', (message) ->
		irc.S('PONG %s', message.text)
	return this
