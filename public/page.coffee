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
					@set "latestCaRomsImagePath_#{variable}", "/data/ca-roms/#{now.getUTCFullYear()}/ca_#{variable}#{padTo2Digits now.getUTCMonth() + 1}#{padTo2Digits now.getUTCDate()}_#{padTo2Digits now.getUTCHours()}_0.jpg"

		class @::RomsContext extends Batman.Model
			varMap =
				curr: "Current"
				salinity: "Salinity and Current"
				ssh: "Sea Surface Height and Current"
				temp: "Temperature and Current"
			@accessor "is03Selected", -> @get("latestTime") is "03 UTC"
			@accessor "is09Selected", -> @get("latestTime") is "09 UTC"
			@accessor "is15Selected", -> @get("latestTime") is "15 UTC"
			@accessor "is21Selected", -> @get("latestTime") is "21 UTC"
			@accessor "imgPath", => "/data/ca-roms/#{now.getUTCFullYear()}/#{@get "region"}_#{@get "variable"}#{padTo2Digits now.getUTCMonth() + 1}#{padTo2Digits now.getUTCDate()}_#{padTo2Digits now.getUTCHours()}_0.jpg"
			@accessor "isCurr", -> @get("variable") is "Current"
			@accessor "isSalinity", -> @get("variable") is "Salinity and Current"
			@accessor "isSSH", -> @get("variable") is "Sea Surface Height and Current"
			@accessor "isTemp", -> @get("variable") is "Temperature and Current"
			constructor: ->
				super
				if varMap[window.location.hash[1..]]?
					@set "variable", window.location.hash[1..]
				else
					@set "variable", "curr"
				@set "region", "ca"
				$("[data-provide=\"datepicker-inline\"]").on "changeDate", (e) =>
					e.date.setMilliseconds e.date.getMilliseconds() - e.date.getTimezoneOffset() * 60 * 1000
					now = @get "now"
					now.setDate e.date.getDate()
					now.setMonth e.date.getMonth()
					now.setFullYear e.date.getFullYear()
				@set "variable", "Current"
			timeChanged: (node) ->
				@get("now").setHours $(node).attr "data-value"
			changeNow: (date) ->
				@set "now", date
				$("[data-provide=\"datepicker-inline\"]").datepicker "update", "#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"
				$(hd = "[data-value=\"#{date.getHours()}\"]").button("toggle") unless $(hd).hasClass "active"
			imageError: ->
				@set "imageError", true
			imageLoad: ->
				@set "imageError", false
			variableChanged: (node) ->
				@set "variable", $(node).attr "data-value"
				#... changeDate?

	class Rompg extends Batman.App
		@appContext: appContext = new AppContext

	Rompg.run()