

# Remove module from node.js's cache (if applicable)
uncache_mod = (name)->
	if require.cache?
		res = require.resolve(MODDIR+name)
		if res of require.cache
			delete require.cache[res]
			console.log("Uncached %s", name)
			
hooks = {}
modules = {}
MODDIR = './modules/'


@load_module = (name) ->
	if name not of modules
			onload = (module)=>
				if typeof module.setup == 'function'
					new Module(name, module.setup)
				else
					console.error "Missing setup function in module #{name}"
			try
				onload require(MODDIR+name)
			catch error
				console.error "Error loading module #{name}"
				console.error error.stack
				for what in hooks
					if hooks[what]?[name]
						delete hooks[what][name]
				throw error
	else
		console.error "Module #{name} already loaded"

@unload_module = (name) ->
	if name of modules
		mod = modules[name]
		mod.terminate?()
		delete @modules[name]
		mod.emit('unloaded', mod)
		uncache_mod(name) 
		return true
	else
		console.error "Error unloading #{name}: module not loaded."
		return false

exports.modules = modules
exports.hooks = hooks

class Hook
	constructor: (@owner, @for, @callback, @modname = '')->
		hooks[@for] ?= []
		hooks[@for][@owner] = this

class Module
	constructor: (@name, func = null)->
		func?.call?(this, this, exports)
		modules[@name] = this
		@emit('loaded', this)
		if hooks['present']?[@name]
			for othermodule in modules
				hooks['present'][@name](othermodule)	
		@emit('present', this)
	remove_hook: (what) ->
		if hooks[what]?
			delete hooks[what][@name]
	
	remove_all_hooks: ->
			count = 0
			for what in hooks
				if delete hooks[what][@name]
					@emit 'log', "Removed #{@what} hook from #{@name}"
					count +=1
			return count
	
	hook: (what, callback)->
		f = new Hook(@name, what, callback)
		@emit 'log', "Module #{@name} hooks #{what}"
		return true

	emit: (what, args...) ->
		r = false
		if what of hooks
			for modname, hook of hooks[what]
				if hook.modname == "" or @name
					try
						hook.callback.call(this, args...)
						r = true
					catch error
						console.error "Error running hook #{what} for module #{modname}:"
						console.error error.stack
		return r
		
coremodule = new Module("modules")

