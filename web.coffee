###
	Author: Gautham Badhrinathan (gotemb@ucla.edu)
	Main start point for the backend. To be run using Coffee (CoffeeScript on NodeJS).
###

express = require "express"
http = require "http"
core = require "./core"

web = express()
web.configure ->
	# Standard Express Routes Configuration (http://expressjs.com)
	web.use express.compress()
	web.use express.bodyParser()
	web.use express.static "#{__dirname}/public", maxAge: 0, (err) -> console.log "Static: #{err}" # HTTP GET <Static files>
	web.use "/data/ca-roms", express.static "#{__dirname}/sampledata", maxAge: 0, (err) -> console.log "Static: #{err}" # HTTP GET <Nowcast images>
	web.set "views", "#{__dirname}/views" # Using jade templates
	web.set "view engine", "jade" # Set template engine to jade
	web.use web.router

# HTTP GET '/'
web.get "/", (req, res) ->
	res.render "home"

# HTTP GET '/roms'
web.get "/ca_roms", (req, res) ->
	res.render "ca_roms", availableRegions: core.getAvailableRegions()

# HTTP GET '/latestROMS.json'
web.get "/latestROMS.json", (req, res) ->
	res.jsonp core.getLatestROMS()

# HTTP GET <Any other page>
web.get /\/([a-z]+)/, (req, res, next) ->
	res.render req.params[0], (err, html) ->
		next() if err
		res.send html

# HTTP 404
web.get "*", (req, res) ->
	res.render "404"

server = http.createServer web

server.listen (port = process.env.PORT ? 5080), -> console.log "Listening on port #{port}"