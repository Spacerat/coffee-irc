###
New callbacks: 
join(Channel, String name) - When a channel has been joined
topic(Channel, String topic)
###

define -> (irc, hook) ->
	@list = {}
	
	@getChannel = (name) =>
		return @list[name] ?= new Channel(name)
	
	class Channel
		constructor: (@name) ->
			@active = false
			@new_names = @names = []
		setTopic: (@topic)->
			irc.emit('topic', this, @topic)
			
		setActive: (@active) ->
			irc.emit('join', this, @name) if (@active) 
		
		say: (message, args) ->
			irc.S("PRIVMSG #{@name} :#{message}", args);
		S: @say
		raw: (message) ->
			irc.R("PRIVMSG #{@name} :#{message}")
		R: @raw
		
		giveNamesList: (list) ->
			@new_names.push(name) for name in list
		endNamesList: () ->
			@names = @new_names
			@new_names = []
			irc.emit('names', this, @names)
	
	###
	irc.do.join(Array Channels, [Array Keys]): join a set of channels with an optional set of passwords
	irc.do.join(String channel, String key): join a channel with an optional password
	###
	irc.do.join = (channels, keys = "") ->
		return false if not channels?
		if typeof channels == 'string'
			if typeof keys != 'string'
				return false
			irc.S("JOIN %s %s", channels, keys)
		else
			keys = [] if keys == ""
			if typeof keys == 'string'
				return false
			irc.S("JOIN %s %s", channels.join(","), keys.join(","))
	
	#Register /join as a user command
	hook '/join', (c) ->
		irc.do.join(c.text)
		
	#Join channels on connection to a server
	hook 'connected', (m) ->
		irc.do.join(irc.config?.channels)
	
	#RPL_TOPIC Reply to TOPIC command topic
	hook '#332', (m) ->
		getChannel(m.args[m.args.length - 1]).setTopic(m.text)
	hook '#TOPIC', (m) ->
		getChannel(m.args[m.args.length - 1]).setTopic(m.text)
	#Successful channel join
	hook '#JOIN', (m) ->
		getChannel(m.text).setActive true
	#Names list
	hook '#353', (m) ->
		getChannel(m.args[m.args.length - 1]).giveNamesList(m.text.split(' '))
	#End names list
	hook '#366', (m) ->
		getChannel(m.args[m.args.length - 1]).endNamesList()
	return this
