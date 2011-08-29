exports.module = (hook, m) ->
	hook '#PING', (irc, message) ->
		irc.S('PONG %s', message.text)
	return this
