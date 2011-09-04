exports.setup = (m, e) ->
	m.prefix = '!'

	m.hook 'message', (irc, text, message) ->
		if text[0] == m.prefix
			command = text.split(' ')[0]
			text = text.split(' ')[1..].join(' ')
			
			data = {}
			for k, v of message
				data[k] = v
			data.text = text
			data.command = command
			data.args = text.split(' ')
			
			irc.emit(command, text, message, data.args...)
			
	m.hook '!hello', (irc, text, message) ->
		if message.channel?.users
			message.reply("Hello "+(user.nick + '!' for user in message.channel.users).join(' '))
		else
			message.reply("Hello #{message.from}!")
			
	m.hook '!say', (irc, text, message) ->
		message.reply(text)
