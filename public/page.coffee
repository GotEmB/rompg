require.config
	paths:
		jquery: "/components/jquery/jquery.min"
		bootstrap: "/components/bootstrap/dist/js/bootstrap.min"
		bootstrapDatepicker: "/components/bootstrap-datepicker/js/bootstrap-datepicker"
		batman: "/batmanjs/batman"
		latestROMS: "/latestROMS.json?callback=define"
	shim:
		bootstrap: deps: ["jquery"]
		bootstrapDatepicker: deps: ["bootstrap"]
		batman: deps: ["jquery"], exports: "Batman"
	waitSeconds: 30

appContext = undefined

define "Batman", ["batman"], (Batman) -> Batman.DOM.readers.batmantarget = Batman.DOM.readers.target and delete Batman.DOM.readers.target and Batman

require ["jquery", "Batman", "latestROMS", "bootstrap", "bootstrapDatepicker"], ($, Batman, latestROMS) ->

	padTo2Digits = (n) -> if n < 10 then "0" + n else n

	getParameterByName = (name) ->
		name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]")
		regex = new RegExp "[\\?&]#{name}=([^&#]*)"
		results = regex.exec location.search
		if results? then decodeURIComponent results[1].replace /\+/g, " " else ""

	class AppContext extends Batman.Model
		constructor: ->
			super
			@set "homeContext", new @HomeContext if window.location.pathname is "/"
			@set "romsContext", new @RomsContext if window.location.pathname is "/roms"

		class @::HomeContext extends Batman.Model
			constructor: ->
				super
				for variable in ["curr", "salinity", "ssh", "temp"]
					now = new Date latestROMS.ca[variable]
					@set "latestCaRomsImagePath_#{variable}", "/data/ca-roms/#{now.getUTCFullYear()}/#{now.getUTCMonth() + 1}/ca_#{variable}#{padTo2Digits now.getUTCMonth() + 1}#{padTo2Digits now.getUTCDate()}_#{padTo2Digits now.getUTCHours()}_0.jpg"

		class @::RomsContext extends Batman.Model
			varMap =
				curr: "Current"
				salinity: "Salinity and Current"
				ssh: "Sea Surface Height and Current"
				temp: "Temperature and Current"
			@accessor "is03Selected", -> @get("now").getUTCHours() is 3
			@accessor "is09Selected", -> @get("now").getUTCHours() is 9
			@accessor "is15Selected", -> @get("now").getUTCHours() is 15
			@accessor "is21Selected", -> @get("now").getUTCHours() is 21
			@accessor "imgPath", -> "/data/ca-roms/#{@get("now").getUTCFullYear()}/#{@get("now").getUTCMonth() + 1}/#{@get "region"}_#{@get "variable"}#{padTo2Digits @get("now").getUTCMonth() + 1}#{padTo2Digits @get("now").getUTCDate()}_#{padTo2Digits @get("now").getUTCHours()}_0.jpg"
			@accessor "regionLongName", -> $("ul>li[data-value=\"#{@get "region"}\"]>a").text()
			for region of latestROMS then do (region) =>
				@accessor "is_#{region}", -> @get("region") is region
			for variable in ["curr", "salinity", "ssh", "temp"] then do (variable) =>
				@accessor "is_#{variable}", -> @get("variable") is variable
			constructor: ->
				super
				if varMap[getParameterByName "variable"]?
					@set "variable", getParameterByName "variable"
				else
					@set "variable", "curr"
				@set "region", "ca"
				@changeNow new Date latestROMS[@get "region"][@get "variable"]
				$("[data-provide=\"datepicker-inline\"]").on "changeDate", (e) =>
					#e.date.setMilliseconds e.date.getMilliseconds() - e.date.getTimezoneOffset() * 60 * 1000
					now = new Date @get "now"
					now.setUTCDate e.date.getDate()
					now.setUTCMonth e.date.getMonth()
					now.setUTCFullYear e.date.getFullYear()
					@set "now", now
				history.replaceState variable: @get("variable"), null, "/roms?variable=#{@get "variable"}"
				window.onpopstate = (e) =>
					@set "variable", e.state?.variable ? "curr"
			timeChanged: (node) ->
				now = new Date @get "now"
				now.setUTCHours $(node).attr "data-value"
				@set "now", now
			changeNow: (date) ->
				@set "now", date
				$("[data-provide=\"datepicker-inline\"]").datepicker "update", "#{date.getUTCMonth() + 1}/#{date.getUTCDate()}/#{date.getUTCFullYear()}"
			imageError: ->
				@set "imageError", true
			imageLoad: ->
				@set "imageError", false
			variableChanged: (node) ->
				return if @get("variable") is $(node).attr "data-value"
				@set "variable", $(node).attr "data-value"
				if @get("now") > now = new Date latestROMS[@get "region"][@get "variable"]
					@changeNow now
				history.pushState variable: @get("variable"), null, "/roms?variable=#{@get "variable"}"
			regionChanged: (node) ->
				return if @get("region") is $(node).attr "data-value"
				@set "region", $(node).attr "data-value"
				if @get("now") > now = new Date latestROMS[@get "region"][@get "variable"]
					@changeNow now

	class Rompg extends Batman.App
		@appContext: appContext = new AppContext

	Rompg.run()

	$ ->
		appContext.set "pageLoaded", true
