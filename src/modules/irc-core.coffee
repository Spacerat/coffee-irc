exports.setup = (m, e) ->
	
	m.clients = []
	
	@IRC = (options) ->
		###
		Private fields
		###
		nickn = -1
		
		obj = {
			###
			Public fields
			###
			connected: false
			nicks: (options.nicks ?= ["Anonymous", "Totally_unique_nick"])
			host: (options.host ?= "") 
			ident: (options.ident ?= "anon")
			realname: (options.realname ?= "Anon")
			config: options
			server: (options.server ?= '')
			port: (options.port ?= 6667)
			
			supports: {
				USER_MODES: 'ov'
				USER_PREFIXES: '@+'
				CHANNEL_MODES: 'CFLMPQcgimnprstz'
				ARG_MODES: 'eIbqkflj'
				PREFIX: {'@': 'o', '+': 'v'} 
				CHANTYPES: '#'
			}
			
			fmt: {
				bold: '\u0002'
				italic: '\u0016'
				underline: '\u001'
			}
			
			###
			Public methods
			###
			
			#Say hi to the server and tell it who we are
			start: ->
				@emit 'socket', @server, @port, =>
					@nick = @nextNick()
					@raw("NICK #{@nick}")
					@raw("USER #{@ident} 8 *: #{@realname}")
	
			disconnect: (silent, reason) ->
				@emit('disconnect')
				if not silent
					@raw("QUIT :%s", reason)
			
			onRaw: (func)->
				@raw = func
			
			sraw: (args...) ->
				@raw args.join(' ')
			
			fraw: (str, args...) ->
				@raw vsprintf(str, args)
			
			nextNick: ->
				nickn +=1
				if @nicks.length == nickn then return null
				return @nicks[nickn]

			# Process a line of input from the server
			recv: (line) ->
				raw = line.trim()
				if line[0] == ":"
					i = line.indexOf(' ')
					hostmask = line.slice(1, i)
					line = line.slice(i + 1)
					if hostmask.indexOf("!") >= 0
						[nick, host] = hostmask.split("!")
					else
						host = hostmask
						nick = ""
				i = line.indexOf(' :')
				args = line.slice(0, i).split(' ')[1...]
				text = line.slice(i + 2)
				cmd = line.slice(0, i).split(' ', 1)[0]
				# The message object, passed to all server command (#) hooks
				message = {
					text: text
					args: args
					command: cmd
					nick: nick
					raw: raw
					line: line
				}
				if (cmd) then @emit('#'+cmd.toUpperCase(), message)
	
			#Emit an event
			#Return a list of callback results, or null if there were no callbacks.
			emit: (what, args...) ->
				m.emit(what, this, args...)
		}
		m.clients.push(obj)
		return obj

	#RPL_ISUPPORT
	m.hook '#005', (irc, message) ->
		for arg in message.args
			[name, val] = arg.split('=')
			switch name
				when "PREFIX"
					groups = /\((.*?)\)(.*)/.exec(str)
					irc.supports.PREFIX = {}
					for i in [0...groups[1].length]
						irc.supports.PREFIX[groups[2][i]] = groups[1][i]
					irc.supports.USER_MODES = groups[1]
					irc.supports.USER_PREFIXES = groups[2]
				when "CHANMODES"
					spl = val.split(",")
					irc.supports.ARG_MODES = spl[0..2].join('')
					irc.supports.CHANNEL_MODES = spl[3]
					
				else
					irc.supports[name] = if val == undefined then true else val


	# Connected to the server
	m.hook '#001', (irc, message) ->
		irc.connected = true
		irc.emit('connected')
		
	# Nick taken
	m.hook '#433', (irc, message) ->
		if (nick = irc.nextNick()) == null
			if not irc.emit('no_nick')
				irc.disconnect()
		irc.raw("NICK %s", nick)

	# Recieved private message
	m.hook '#PRIVMSG', (irc, message) ->
		to = message.args[0]
		from = ''
		if (to[0] in irc.supports.CHANTYPES) and (channel = e.modules['irc-channels'].get(irc, to))
			type = 'Channel'
			from = channel.name
		else
			type = 'Personal'
			from = message.nick
		data = {		
			text: message.text
			type: type
			channel: channel
			nick: message.nick
			to: to
			from: from
			reply: (message, args...) ->
				irc.raw("PRIVMSG #{from} :#{message}", args...)
		}
		irc.emit('message', message.text, data)


`var sprintf=function(){function g(i){return Object.prototype.toString.call(i).slice(8,-1).toLowerCase()}var c=function(){c.cache.hasOwnProperty(arguments[0])||(c.cache[arguments[0]]=c.parse(arguments[0]));return c.format.call(null,c.cache[arguments[0]],arguments)};c.format=function(i,e){var c=1,j=i.length,a="",h=[],d,f,b,k;for(d=0;d<j;d++)if(a=g(i[d]),a==="string")h.push(i[d]);else if(a==="array"){b=i[d];if(b[2]){a=e[c];for(f=0;f<b[2].length;f++){if(!a.hasOwnProperty(b[2][f]))throw sprintf('[sprintf] property "%s" does not exist',
b[2][f]);a=a[b[2][f]]}}else a=b[1]?e[b[1]]:e[c++];if(/[^s]/.test(b[8])&&g(a)!="number")throw sprintf("[sprintf] expecting number but found %s",g(a));switch(b[8]){case "b":a=a.toString(2);break;case "c":a=String.fromCharCode(a);break;case "d":a=parseInt(a,10);break;case "e":a=b[7]?a.toExponential(b[7]):a.toExponential();break;case "f":a=b[7]?parseFloat(a).toFixed(b[7]):parseFloat(a);break;case "o":a=a.toString(8);break;case "s":a=(a=String(a))&&b[7]?a.substring(0,b[7]):a;break;case "u":a=Math.abs(a);
break;case "x":a=a.toString(16);break;case "X":a=a.toString(16).toUpperCase()}a=/[def]/.test(b[8])&&b[3]&&a>=0?"+"+a:a;f=b[4]?b[4]=="0"?"0":b[4].charAt(1):" ";k=b[6]-String(a).length;if(b[6]){for(var l=[];k>0;l[--k]=f);f=l.join("")}else f="";h.push(b[5]?a+f:f+a)}return h.join("")};c.cache={};c.parse=function(c){for(var e=[],g=[],j=0;c;){if((e=/^[^\x25]+/.exec(c))!==null)g.push(e[0]);else if((e=/^\x25{2}/.exec(c))!==null)g.push("%");else if((e=/^\x25(?:([1-9]\d*)\$|\(([^\)]+)\))?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(c))!==
null){if(e[2]){j|=1;var a=[],h=e[2],d=[];if((d=/^([a-z_][a-z_\d]*)/i.exec(h))!==null)for(a.push(d[1]);(h=h.substring(d[0].length))!=="";)if((d=/^\.([a-z_][a-z_\d]*)/i.exec(h))!==null)a.push(d[1]);else if((d=/^\[(\d+)\]/.exec(h))!==null)a.push(d[1]);else throw"[sprintf] huh?";else throw"[sprintf] huh?";e[2]=a}else j|=2;if(j===3)throw"[sprintf] mixing positional and named placeholders is not (yet) supported";g.push(e)}else throw"[sprintf] huh?";c=c.substring(e[0].length)}return g};return c}(),vsprintf=
function(g,c){c.unshift(g);return sprintf.apply(null,c)};`

