require.config
	paths:
		jquery: "/components/jquery/jquery.min"
		bootstrap: "/components/bootstrap/dist/js/bootstrap.min"
		bootstrapDatepicker: "/components/bootstrap-datepicker/js/bootstrap-datepicker"
		batman: "batmanjs/batman"
	shim:
		bootstrap: deps: ["jquery"]
		bootstrapDatepicker: deps: ["bootstrap"]
		batman: deps: ["jquery"], exports: "Batman"
	waitSeconds: 30

appContext = undefined

define "Batman", ["batman"], (Batman) -> Batman.DOM.readers.batmantarget = Batman.DOM.readers.target and delete Batman.DOM.readers.target and Batman

require ["jquery", "Batman", "bootstrap", "bootstrapDatepicker"], ($, Batman) ->

	class AppContext extends Batman.Model
		constructor: ->
			super
			@set "homeContext", new @HomeContext if window.location.pathname is "/"
			@set "romsContext", new @RomsContext if window.location.pathname is "/roms"

		class @::HomeContext extends Batman.Model
			constructor: ->
				super
				now = new Date
				now.setDate now.getDate() - 1 if Math.floor((now.getUTCHours() - 3) / 6) < 0
				time = ((Math.floor (now.getUTCHours() - 3) / 6 + 4) % 4) * 6 + 3
				@set "latestCaRomsImagePath", "/data/ca-roms/#{now.getUTCFullYear()}/ca_curr#{now.getUTCMonth() + 1}#{now.getUTCDate()}_#{if time < 10 then "0" + time else time}_0.jpg"
				@set "latestCaRomsImageError", false
			latestCaRomsImageError: ->
				@set "latestCaRomsImageError", true

		class @::RomsContext extends Batman.Model
			constructor: ->
				super
				@set "currentTab", "caRoms"
				@set "caRoms", new @CaRoms

			class @::CaRoms extends Batman.Model
				varMap =
					"Current": "curr"
					"Salinity and Current": "salinity"
					"Sea Surface Height and Current": "ssh"
					"Temperature and Current": "temp"
				@accessor "is03Selected", -> @get("latestTime") is "03 UTC"
				@accessor "is09Selected", -> @get("latestTime") is "09 UTC"
				@accessor "is15Selected", -> @get("latestTime") is "15 UTC"
				@accessor "is21Selected", -> @get("latestTime") is "21 UTC"
				@accessor "imgPath", -> "/data/ca-roms/#{@get("latestDate").getUTCFullYear()}/ca_#{varMap[@get "variable"]}#{@get("latestDate").getUTCMonth() + 1}#{@get("latestDate").getUTCDate()}_#{@get("latestTime").match(/^[0-9]+/g)[0]}_0.jpg"
				@accessor "isCurr", -> @get("variable") is "Current"
				@accessor "isSalinity", -> @get("variable") is "Salinity and Current"
				@accessor "isSSH", -> @get("variable") is "Sea Surface Height and Current"
				@accessor "isTemp", -> @get("variable") is "Temperature and Current"
				constructor: ->
					super
					now = new Date
					now.setDate now.getDate() - 1 if Math.floor((now.getUTCHours() - 3) / 6) < 0
					@changeDate now
					time = ((Math.floor (now.getUTCHours() - 3) / 6 + 4) % 4) * 6 + 3
					@set "latestTime", "#{if time < 10 then "0" + time else time} UTC"
					$("[data-provide=\"datepicker-inline\"]").on "changeDate", (e) =>
						e.date.setMilliseconds e.date.getMilliseconds() - e.date.getTimezoneOffset() * 60 * 1000
						@set "latestDate", e.date
					@set "variable", "Current"
				timeChanged: (node) ->
					@set "latestTime", $(node).attr "data-value"
				changeTime: (time) ->
					node = $("[data-value=\"#{time}\"]")[0]
					$(node).button("toggle") unless $(node).hasClass "active"
				changeDate: (date) ->
					@set "latestDate", date
					$("[data-provide=\"datepicker-inline\"]").datepicker "update", "#{date.getUTCMonth() + 1}/#{date.getUTCDate()}/#{date.getUTCFullYear()}"
				imageError: ->
					@set "imageError", true
				imageLoad: ->
					@set "imageError", false
				variableChanged: (node) ->
					@set "variable", $(node).attr "data-value"
	class Rompg extends Batman.App
		@appContext: appContext = new AppContext

	Rompg.run()