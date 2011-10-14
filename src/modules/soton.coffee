http = require('http')
querystring = require('querystring')

exports.setup = (m, e) ->
	m.hook '!building', (irc, text, message) ->
		if (text.length < 3)
			message.reply("Query too short. Please use at least three characters.")
			return
		term = text.replace(/'/, '\\\'');
		query = "
			PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
			PREFIX soton: <http://id.southampton.ac.uk/ns/>
			PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
			PREFIX org: <http://www.w3.org/ns/org#>
			PREFIX spacerel: <http://data.ordnancesurvey.co.uk/ontology/spatialrelations/>

			SELECT DISTINCT ?number ?name ?occupants ?code WHERE {
				?site a org:Site ;
						  rdfs:label \"Highfield Campus\" .

				?building spacerel:within ?site ;
						      skos:notation ?number ;
						      rdfs:label ?name ;
						      FILTER (regex(?name, '#{term}', 'i') || regex(?occupants, '#{term}', 'i')) .

				OPTIONAL {
					?building soton:buildingOccupants ?occ .
					?occ rdfs:label ?occupants .
				} .
			} ORDER BY ?name
			"
		query = querystring.stringify({query: query, output: 'json'})
		options = {
			host: "sparql.data.southampton.ac.uk"
			method: "GET"
			path: "?#{query}"
		}
		http.get options, (res) ->
			res.setEncoding('utf8')
			buff = ''
			res.on 'data', (chunk) ->
				buff += chunk
				return
			res.on 'end', () ->
				try
					data = JSON.parse(buff)
				catch error
					console.log(error)
					message.reply(buff)
					return
				i = 0
				say = () ->
					if ((building = data.results.bindings[i])?)
						console.log building
						if (building.occupants?)
							message.reply("#{building.name.value} (#{building.number.value}) - #{building.occupants.value}")
						else
							message.reply("#{building.name.value} (#{building.number.value})")				
						i++
						if i < 11 then setTimeout(say, 300)
				say()

						
						
