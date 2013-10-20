require.config
	paths:
		jquery: "/jquery/jquery-2.0.3.min"
		batman: "/batmanjs/batman"
		bootstrap: "/twbs/bootstrap.min"
	shim:
		batman: deps: ["jquery"], exports: "Batman"
		bootstrap: deps: ["jquery"]
		facebook: exports: "FB"
		socket_io: exports: "io"
	waitSeconds: 30

appContext = undefined

define "Batman", ["batman"], (Batman) -> Batman.DOM.readers.batmantarget = Batman.DOM.readers.target and delete Batman.DOM.readers.target and Batman

require ["jquery", "Batman", "bootstrap"], ($, Batman) ->

	$ ->
		# ...