express = require "express"
http = require "http"
mongoose = require "mongoose"

mongoose.connect process.env.MONGODBSTR
mongoose.connection.once "error", ->
	console.error "Mongo Error: ", arguments
	process.exit 1

Task = mongoose.model "Task",
	taskId: String

web = express()
web.configure ->

	web.use express.compress()
	web.use express.bodyParser()
	web.use express.static "#{__dirname}/public", maxAge: 0, (err) -> console.log "Static: #{err}"
	web.use "/data/ca-roms", express.static process.env.CAROMS_DIR, maxAge: 0, (err) -> console.log "Static: #{err}"
	web.set "views", "#{__dirname}/views"
	web.set "view engine", "jade"
	web.use web.router

web.get "/", (req, res) ->
	res.render "home"

web.get /\/([a-z]+)/, (req, res, next) ->
	res.render req.params[0], (err, html) ->
		next() if err
		res.send html

web.get "*", (req, res) ->
	res.render "404"

server = http.createServer web

mongoose.connection.once "open", ->
	console.log "Connected to MongoDB"
	server.listen (port = process.env.ROMPG_PORT ? 5080), -> console.log "Listening on port #{port}"
