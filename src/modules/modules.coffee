
exports.modules = ()->
		@modules = {}
		@hooks = {}
		
		add_hook = (mname) => (hook, cb) =>
			@hooks[mname][hook] ?= []
			console.log "Registered hook #{hook} for module #{mname}"
			@hooks[mname][hook].push(cb)	
		
		uncache_mod = (name)->
			res = require.resolve('./'+name)
			if res of require.cache
				delete require.cache[res]
		
		@m = (mname) => @modules[mname]

	
		@emit = (what, args...) =>
			for name, module of @hooks
				if what of @hooks[name] then for cb in @hooks[name][what]
					try
						cb(args...)
					catch error
						console.error "Error in module #{name}(#{what}): "
						console.error error.stack
	
		@unload_module = (name, args...) =>
			name = name.trim()
			if name of @modules
				#irc.emit('unload', name)
				@modules[name].terminate?(args...)
				delete @modules[name]
				delete @hooks[name]
				uncache_mod(name)
				console.log "Unloaded module #{name}"
			
		@load_module = (name, args...) ->
			name=name.trim()
			if not (name of @modules)
				fail = false
				onload = (func) =>
					me = this
					if typeof func == 'function'
						@hooks[name] = {}
						@modules[name] = new func(add_hook(name), this)
						if @hooks[name].init?
							cb(args...) for cb in @hooks[name].init
						@modules[name].init?(args...)
						console.log "Loaded module %s", name
					else
						uncache_mod(name)
						console.log "Error loading module #{name}, module does not return a function."
				onload require('./'+name).module
				###
				requirejs.onError = (error) ->
					fail = true
					irc.L error.message
				if not (require.nodeRequire?)
					requirejs ['./'+name+".js"], (mod) =>
						if fail then return
						onload mod
				else
					console.log require.nodeRequire
					onload require.nodeRequire("#{name}")
				return true
				###
			else
				console.log "Attempt to load already loaded module %s", name
				return false
		
		###
		for own i, name of modules
			@hooks[name] = {}
			@modules[name] = new modlist[i] add_hook(name), this
		###
		return this
	
