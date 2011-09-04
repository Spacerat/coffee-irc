

exports.setup = (m, e) ->

	class User
		constructor: (@nickstr, irc, @modes = []) ->
			if @nickstr[0] in irc.supports.USER_MODES
				@modes[irc.supports.PREFIX[@nickstr[0]]] = true
				@nick = @nickstr[1..]
			else
				@nick = @nickstr
		
			

	class Channel
		constructor: (@name, @irc) ->
			@active = false
			@new_users = @users = []
			@topic = ''
			
		setTopic: (@topic)->
			@irc.emit('topic', this, @topic)
			
		part: () ->
			@irc.raw("PART "+@name)
			
		newUser: (name) ->
			@users.push(new User(name, @irc))
			@irc.emit('joined', this, name)
		
		giveNamesList: (list) ->
			@new_users.push(new User(name, @irc)) for name in list
		endNamesList: () ->
			@users = @new_users
			@new_users = []
			@irc.emit('users', this, @users)


	m.channels = {}

	###
		m.get(irc): Get a list of all channels for a network
		m.get(irc, channel): Get a channel by its network and name, create it if it doesn't exit.
	###
	m.get = (irc, channel)->
		m.channels[irc.network] ?= {}
		if (typeof channel == 'string')
			channel = channel.toLowerCase()
			
			if (ch = m.channels[irc.network]?[channel])
				return ch
			else
				return (m.channels[irc.network][channel] = new Channel(channel, irc))
		else
			return m.channels[irc.network]
	
	###
	irc.do.join(Array Channels, [Array Keys]): join a list of channels with an optional list of passwords
	irc.do.join(String channel, String key): join a channel with an optional password
	###
	m.join = (irc, channels, keys = "") ->
		return false if not channels?
		if typeof channels == 'string'
			if typeof keys != 'string'
				return false
			irc.fraw("JOIN %s %s", channels, keys)
		else
			keys = [] if keys == ""
			if typeof keys == 'string'
				return false
			irc.fraw("JOIN %s %s", channels.join(","), keys.join(","))

	# Join channels in config upon connection
	m.hook 'connected', (irc) ->
		m.join(irc, irc.config?.channels)
	
	# Recieve names from a NAMES list
	m.hook '#353', (irc, message) ->
		m.get(irc, message.args[2]).giveNamesList(message.text.split(' '))
	# Stop recieving names from a NAMES list
	m.hook '#366', (irc, message) ->
		m.get(irc, message.args[1]).endNamesList()
		
	# Get a list of channels we're in
	m.hook '#319', (irc, message) ->
		for chan in message.text.split(' ')
			m.get(irc, chan)
			irc.raw("NAMES #{chan}")
			
	# Someone (possibly us) joined a channel
	m.hook '#JOIN', (irc, message) ->
		if (irc.nick != message.nick)
			m.get(irc, message.text).newUser(message.nick)

	#RPL_TOPIC and TOPIC
	m.hook '#332', (irc, message) ->
		m.get(irc, message.args[1]).setTopic(message.text)
	m.hook '#TOPIC', (irc, message) ->
		m.get(irc, message.args[0]).setTopic(message.text)
		
	
	# Upon module initialisation, find out which channels we're in
	for irc in e.modules['irc-core']?.clients
		irc.raw("WHOIS #{irc.nick}")

