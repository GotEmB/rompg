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
	web.set "views", "#{__dirname}/views"
	web.set "view engine", "jade"
	web.use web.router

web.get "/", (req, res) ->
	res.render "home", newsInfo: require "./sampledata/newsInfo"

web.get "/vision", (req, res) ->
	res.render "vision"

server = http.createServer web

mongoose.connection.once "open", ->
	console.log "Connected to MongoDB"
	server.listen (port = process.env.PORT ? 5080), -> console.log "Listening on port #{port}"