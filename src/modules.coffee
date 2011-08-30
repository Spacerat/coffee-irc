
###
Uncache a module (if applicable)
###
uncache_mod = (name)->
	if require.cache?
		res = require.resolve('./'+name)
		if res of require.cache
			delete require.cache[res]


###
Callback class
###
class Callback
	constructor: (@function, @for, @owner)->
	
	run: (parent, args...)->
		@function(parent, args...)


###
EventEmitter class
###
class Module
	
	constructor: (@name, @parent) ->
		@modules = {}
		@hooks = {}
	
	###
		Emit an event for all child modules
	###
	emit: (what, args...) ->
		@propagate_for(this, what, args...)
		
	propagate_for: (mod, what, args...) ->
		if what of @hooks
			for name, cb of @hooks[what]
				cb.run(mod, args...)
		for child in @modules
			child.propagate_for(mod, what, args...)
			
	propagate_for_excluding: (mod, exclude, what, args...) ->
		if what of @hooks
			for name, cb of @hooks[what]
				cb.run(mod, args...)
		for child in @modules
			child.propagate_for(mod, what, args...) if child != exclude
			
	###
		Emit an event, and cause all parents to emit the event
	###
	bubble: (what, args...)->
		@emit(what, args...)
		@parent?.bubble_for(this, what, args...)
		
	bubble_for: (mod, what, args...) ->
		if what of @hooks
			cb.run(mod, args...) for name, cb of @cabllbacks[what]
		@parent?.bubble_for(mod, what)
		@parent?.propagate_for_excluding(mod, this, what, args...)
	###
		Add a callback to this module
	###
	on: (what, owner, cb = null) ->
		if cb == null
			cb = owner
			owner = null
		func = new Callback(cb, what, owner)
		@hooks[what]?= []
		@hooks[what].push(func)
		
	###
		Load a module by file name
	###
	load_module: (name, args...) ->
		if name not of @modules
			onload = (func)=>
				if typeof func == 'function'
					console.log name
					cl = func(Module) #Pass a new Module instance to the module
					mod = new cl(name, this)
					@modules[name] = mod
					mod.bubble('load module')
			onload require('./'+name).module
	
	terminate: () ->
		@bubble('unload module')
		@onTerminate?()
	###
		Unload a module by (file) name
	###
	unload_module: (name) ->
		if name of @modules
			mod = @modules[name]
			mod.terminate()
			delete @modules[name]
			uncache_mod(name)
			console.log "Unloaded module #{name}"
			return true
			

exports.Module = Module
