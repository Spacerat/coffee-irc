###
An IRC library which doesn't depend on any other libraries for functionality,
Although I suppose it technically depends on requireJS and coffeescript.
###

define ['./modules'], (modules) ->
	 
	Client: class Client
		###
			Callbacks:
				send(data) - Called to send data to the server
				log(string) - Called with debugging/loggin stuff
		###
	
		#Create a new IRC class.
		constructor: (options)->
			@cb = {}
			
			@nicks = (options.nicks ?= ["Anonymous", "Totally_unique_nick"])
			@nickn = 0
			@nick = @nicks[@nickn]
			@host = (options.host ?= "")
			@ident = (options.ident ?= "anon")
			@realname = (options.realname ?= "Anon")
			@config = options
			
			@modules = {}
			
			@do = {} # Actions object. Modules store globally useful functionality here.

		load_default_modules: ->
			#Each module is a function which takes arguments (irc, hook)
			for module in modules
				@L("Loading %s", module.mod_name)
				@modules[module.mod_name] = module
				module.hooks = {}
				module.data = module this, (what, callback)=>
					#Create the module's hook function here.
					@module_on(module.mod_name, what, callback)
				
				
				
		#Load modules and say hi to the server and tell it who we are
		#This could be in a module, but... really?
		start: ->
		
			@S('NICK %s', @nick)
			@S('USER %s 8 *: %s', @ident, @realname)
		
		#Register an event callback for a module
		module_on: (module, what, callback) ->
			if module of @modules
				@modules[module].hooks[what] ?= []
				@modules[module].hooks[what].push(callback)
				@L('Registered callback %s for module %s', what, module)
			else
				@L('Attempt to register callback %s for non-existant module %s', what, module)
			
		#Register a callback for an event
		on: (what, callback) ->
			@cb[what] ?= []
			@cb[what].push(callback)
		
		disconnect: (silent, reason) ->
			emit('disconnect')
			if not silent
				@S("QUIT :%s", reason)
			
		
		nextNick: ->
			@nickn +=1
			if @nicks.length = @nickn then return null
			return @nicks[@nickn]
		
		#Process a line of input from the client
		input: (line) ->
			if line[0] == "/"
				i = line.indexOf(' ')
				if i?
					cmd = line.split(' ', 1)
					str = line.slice(i + 1)
				else
					cmd = line
					str = ''
				# The arguments object, passed to all user command (/) hooks
				args = str.split(' ')
				arguments = {
					text: str
					command: cmd
					args: args
				}
				@emit(cmd, arguments, args...)

		# Process a line of input from the server
		recv: (line) ->
			raw = line
			if line[0] == ":"
				i = line.indexOf(' ')
				hostmask = line.slice(1, i)
				line = line.slice(i + 1)
				console.log
				if hostmask.indexOf("!") >= 0
					[nick, host] = hostmask.split("!")
				else
					host = hostmask
					nick = ""
			i = line.indexOf(' :')
			args = line.slice(0, i).split(' ')
			text = line.slice(i + 2)
			cmd = args[0]
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
		#Internal: shortcuts for stuff
		S: (str, args...) -> @emit('send', vsprintf(str, args)) # Formatted send
		L: (str, args...) -> @emit('log', vsprintf(str, args)) # Formatted log
		R: (str) -> @emit('send', str) #Raw send
		
		# Get the data for a module, if it exists
		m: (name)-> return @modules[name]?.data
		#Emit an event
		#Return a list of callback results, or null if there were no callbacks.
		emit: (what, args...) ->
			if what of @cb then for cb in @cb[what]
				cb(args...)
			for name, module of @modules
				if what of module.hooks then for cb in module.hooks[what]
					cb(args...)
				
			
				
				
				
`var sprintf=function(){function g(i){return Object.prototype.toString.call(i).slice(8,-1).toLowerCase()}var c=function(){c.cache.hasOwnProperty(arguments[0])||(c.cache[arguments[0]]=c.parse(arguments[0]));return c.format.call(null,c.cache[arguments[0]],arguments)};c.format=function(i,e){var c=1,j=i.length,a="",h=[],d,f,b,k;for(d=0;d<j;d++)if(a=g(i[d]),a==="string")h.push(i[d]);else if(a==="array"){b=i[d];if(b[2]){a=e[c];for(f=0;f<b[2].length;f++){if(!a.hasOwnProperty(b[2][f]))throw sprintf('[sprintf] property "%s" does not exist',
b[2][f]);a=a[b[2][f]]}}else a=b[1]?e[b[1]]:e[c++];if(/[^s]/.test(b[8])&&g(a)!="number")throw sprintf("[sprintf] expecting number but found %s",g(a));switch(b[8]){case "b":a=a.toString(2);break;case "c":a=String.fromCharCode(a);break;case "d":a=parseInt(a,10);break;case "e":a=b[7]?a.toExponential(b[7]):a.toExponential();break;case "f":a=b[7]?parseFloat(a).toFixed(b[7]):parseFloat(a);break;case "o":a=a.toString(8);break;case "s":a=(a=String(a))&&b[7]?a.substring(0,b[7]):a;break;case "u":a=Math.abs(a);
break;case "x":a=a.toString(16);break;case "X":a=a.toString(16).toUpperCase()}a=/[def]/.test(b[8])&&b[3]&&a>=0?"+"+a:a;f=b[4]?b[4]=="0"?"0":b[4].charAt(1):" ";k=b[6]-String(a).length;if(b[6]){for(var l=[];k>0;l[--k]=f);f=l.join("")}else f="";h.push(b[5]?a+f:f+a)}return h.join("")};c.cache={};c.parse=function(c){for(var e=[],g=[],j=0;c;){if((e=/^[^\x25]+/.exec(c))!==null)g.push(e[0]);else if((e=/^\x25{2}/.exec(c))!==null)g.push("%");else if((e=/^\x25(?:([1-9]\d*)\$|\(([^\)]+)\))?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(c))!==
null){if(e[2]){j|=1;var a=[],h=e[2],d=[];if((d=/^([a-z_][a-z_\d]*)/i.exec(h))!==null)for(a.push(d[1]);(h=h.substring(d[0].length))!=="";)if((d=/^\.([a-z_][a-z_\d]*)/i.exec(h))!==null)a.push(d[1]);else if((d=/^\[(\d+)\]/.exec(h))!==null)a.push(d[1]);else throw"[sprintf] huh?";else throw"[sprintf] huh?";e[2]=a}else j|=2;if(j===3)throw"[sprintf] mixing positional and named placeholders is not (yet) supported";g.push(e)}else throw"[sprintf] huh?";c=c.substring(e[0].length)}return g};return c}(),vsprintf=
function(g,c){c.unshift(g);return sprintf.apply(null,c)};`

