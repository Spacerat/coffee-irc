
exports.modules = ()->
		@modules = {}
		@hooks = {}
		
		###
		mname: module name
		returns a function(hook, callback) used by modules to register hooks
		###
		add_hook = (mname) => (hook, cb) =>
			@hooks[mname][hook] ?= []
			console.log "Registered hook #{hook} for module #{mname}"
			@hooks[mname][hook].push(cb)	
		
		###
			Uncache a module (if applicable)
		###
		uncache_mod = (name)->
			res = require.resolve('./'+name)
			if res of require.cache
				delete require.cache[res]
				
		#Shorcut for accessing a module, e.g. @m.m('channels').join()
		@m = (mname) => @modules[mname]
		
		###
		Emit an event to all registered modules
			what:   event name
			args... passed to callbacks
		Returns a list of callback return values, or nothing if there were no callbacks
		###
		@emit = (what, args...) =>
			for name, module of @hooks
				if what of @hooks[name] then for cb in @hooks[name][what]
					try
						cb(args...)
					catch error
						console.error "Error in module #{name}(#{what}): "
						console.error error.stack
						false # push 'false' to the result list
	
		###
		Unload a module
			name:   module name
			args... passed to module.terminate()
		Returns true if a module was unloaded
		###
		@unload_module = (name, args...) =>
			name = name.trim()
			if name of @modules
				#irc.emit('unload', name)
				@modules[name].terminate?(args...)
				delete @modules[name]
				delete @hooks[name]
				uncache_mod(name)
				console.log "Unloaded module #{name}"
				return true
		
		###
		Load a module
			name:   module name
			args... passed to module module.init()
		Returns the new module or false
		###
		@load_module = (name, args...) ->
			name=name.trim()
			if not (name of @modules)
				fail = false
				onload = (func) =>
					me = this
					if typeof func == 'function'
						@hooks[name] = {}
						@modules[name] = new func(add_hook(name), this)
						@modules[name].init?(args...)
						console.log "Loaded module %s", name
						return @modules[name]
					else
						uncache_mod(name)
						console.log "Error loading module #{name}, module does not return a function."
						return false
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
		
		return this
	
