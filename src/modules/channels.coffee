###
New callbacks: 
join(Channel, String name) - When a channel has been joined
topic(Channel, String topic)
###

exports.module = (hook, m) ->
	
	getChannel = (irc, name) =>
		return irc.channels[name] ?= new Channel(irc, name)
	clients = []
	
	class Channel
		constructor: (@irc, @name) ->
			@active = false
			@new_names = @names = []
		setTopic: (@topic)->
			@irc.emit('topic', this, @topic)
			
		setActive: (@active) ->
			@irc.emit('enter', this, @name) if (@active) 
		
		say: (message, args) ->
			@irc.S("PRIVMSG #{@name} :#{message}", args);
		S: @say
		raw: (message) ->
			@irc.R("PRIVMSG #{@name} :#{message}")
		R: @raw
		
		part: () ->
			@irc.S("PART "+@name)
			
		newUser: (name) ->
			@names.push(name)
			@irc.emit('join', this, name)
		
		giveNamesList: (list) ->
			@new_names.push(name.trim()) for name in list
		endNamesList: () ->
			@names = @new_names
			@new_names = []
			@irc.emit('names', this, @names)
	
	###
	irc.do.join(Array Channels, [Array Keys]): join a set of channels with an optional set of passwords
	irc.do.join(String channel, String key): join a channel with an optional password
	###
	@join = (irc, channels, keys = "") ->
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
	
	#Disconnect from all channels if the module is unloaded
	@terminate = (args...)->
		for irc in clients
			console.log irc
			for name, channel of irc?.channels
				channel.part()
			delete irc.channels
	
	#When an IRC client initialises, append it to our list of clients
	hook 'init', (irc, args...) ->
		irc.channels ?= {}
		clients.push(irc)
	
	#Register /join as a user command
	hook '/join', (irc, c) =>
		@join(irc, c.text)
		
	#Join channels on connection to a server
	hook 'connected', (irc, message) =>
		@join(irc, irc.config?.channels)
	
	
	#RPL_TOPIC Reply to TOPIC command topic
	hook '#332', (irc, message) ->
		getChannel(irc, message.args[message.args.length - 1]).setTopic(message.text)
	hook '#TOPIC', (irc, message) ->
		getChannel(irc, message.args[message.args.length - 1]).setTopic(message.text)
	#Successful channel join
	hook '#JOIN', (irc, message) ->
		if (irc.nick == message.nick)
			getChannel(irc, message.text).setActive true
		else
			getChannel(irc, message.text).names.push(message.nick)
			
	#Names list
	hook '#353', (irc, message) ->
		getChannel(irc, message.args[message.args.length - 1]).giveNamesList(message.text.split(' '))
	#End names list
	hook '#366', (irc, message) ->
		getChannel(irc, message.args[message.args.length - 1]).endNamesList()
	return this
