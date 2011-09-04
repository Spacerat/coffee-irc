exports.setup = (m, e) ->
	process.stdin.resume()
	process.stdin.setEncoding('utf8')	
	last_irc = null
	m.hook 'log', console.log
	
	process.stdin.on 'data', (line) ->
		line = line.trim()
		if line[0] == '/'
			spl = line.split(' ')
			cmd = spl[0]
			args = spl[1..]
			m.emit(spl[0], args.join(' '), args...)

	m.hook '/load', (string, names...) =>
		e.load_module(name) for name in names
	m.hook '/unload', (string, names...) =>
		e.unload_module(name) for name in names
	m.hook '/reload', (string, names...) =>
		e.unload_module(name) for name in names
		e.load_module(name) for name in names
		
	m.hook 'connected', (irc) =>
		last_irc = irc
	m.hook '/raw', (string) =>
		last_irc?.raw(string)
