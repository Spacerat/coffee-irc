#Here is the list of modules that the irc.coffee module should load
modules = [
	'ping'
	'channels'
	'core'
]


define (modules.map (str) -> './'+str), ->
	for own i, name of modules
		arguments[i].mod_name = name
	return arguments
