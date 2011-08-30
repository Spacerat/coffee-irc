exports.module = (Module)->	class stdio extends Module
	constructor: (name, parent) ->
	
		super name, parent
		process.stdin.resume()
		process.stdin.on 'data', (line)->
			#if line.indexOf('/') == 0
		
		@on 'load module', this, (args...) ->
			console.log(args...)
