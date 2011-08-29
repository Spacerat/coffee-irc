exports.module = (hook, m) ->
	hook 'message', (irc, line, message) ->
		if line.toLowerCase().indexOf("!hello") == 0 and (message.channel)
			message.reply(message.channel.names.join('! ')+'!')
			
	@terminate = (args...) ->
			console.log("!!")
	return this
