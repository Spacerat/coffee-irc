exports.setup = (m, e) ->
	m.hook '#PING', (irc, message) ->
		irc.raw("PONG #{message.text}")
