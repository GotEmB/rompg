###
	Author: Gautham Badhrinathan (gotemb@ucla.edu)
	Main client-side application logic. Uses RequireJS.
###

# Standard RequireJS Config (http://requirejs.org)
require.config
	paths:
		jquery: "/components/jquery/jquery.min"
		bootstrap: "/components/bootstrap/dist/js/bootstrap.min"
		bootstrapDatepicker: "/components/bootstrap-datepicker/js/bootstrap-datepicker"
		batman: "/batmanjs/batman"
		latestCARoms: "/latestCARoms.json?callback=define"
		latestPWSRoms: "/latestPWSRoms.json?callback=define"
		leaflet: "//cdn.leafletjs.com/leaflet-0.7.1/leaflet"
		esriLeaflet: "/esri-leaflet/esri-leaflet"
	shim:
		bootstrap: deps: ["jquery"]
		bootstrapDatepicker: deps: ["bootstrap"]
		batman: deps: ["jquery"], exports: "Batman"
		leaflet: exports: "L"
		esriLeaflet: deps: ["leaflet"]
	waitSeconds: 30

# Expose `appContext` globally (for debugging only)
appContext = undefined

# Resolve `data-target` conflicts between BatmanJS and Bootstrap
define "Batman", ["batman"], (Batman) -> Batman.DOM.readers.batmantarget = Batman.DOM.readers.target and delete Batman.DOM.readers.target and Batman

# Main Function that'll run once all modules are loaded
require ["jquery", "Batman", "latestCARoms", "latestPWSRoms", "leaflet", "bootstrap", "bootstrapDatepicker", "esriLeaflet"], ($, Batman, latestCARoms, latestPWSRoms, L) ->

	# Pad Digits. Ex. 1 -> 01; 10 -> 10
	padTo2Digits = (n) -> if n < 10 then "0" + n else n

	# Get queryParam by name (code converted from http://stackoverflow.com/a/901144/915479)
	getParameterByName = (name) ->
		name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]")
		regex = new RegExp "[\\?&]#{name}=([^&#]*)"
		results = regex.exec location.search
		if results? then decodeURIComponent results[1].replace /\+/g, " " else ""

	# Main BatmanJS Context Model
	class AppContext extends Batman.Model
		constructor: ->
			super

			# Required Page Model gets instantiated
			@set "homeContext", new @HomeContext if window.location.pathname is "/"
			@set "romsCAContext", new @RomsCAContext if window.location.pathname is "/ca_roms"
			@set "romsPWSContext", new @RomsPWSContext if window.location.pathname is "/pws_roms"
			@set "interactiveContext", new @InteractiveContext if window.location.pathname is "/interactive"

		# Page Model for HTTP GET '/'
		class @::HomeContext extends Batman.Model
			constructor: ->
				super

				# Set paths for each of the four imagery shown on the homepage
				for variable in ["curr", "salinity", "ssh", "temp"]
					now = new Date latestRoms.ca[variable]
					@set "latestCaRomsImagePath_#{variable}", "/data/ca-roms/#{now.getUTCFullYear()}/#{padTo2Digits now.getUTCMonth() + 1}/ca_#{variable}#{padTo2Digits now.getUTCMonth() + 1}#{padTo2Digits now.getUTCDate()}_#{padTo2Digits now.getUTCHours()}_0.jpg"

		# Page Model for HTTP GET '/ca_roms'
		class @::RomsCAContext extends Batman.Model
			varMap =
				curr: "Current"
				salinity: "Salinity and Current"
				ssh: "Sea Surface Height and Current"
				temp: "Temperature and Current"
			
			# Setup property accessors
			@accessor "imgPath", -> "/data/ca-roms/#{@get("now").getUTCFullYear()}/#{padTo2Digits @get("now").getUTCMonth() + 1}/#{@get "region"}_#{@get "variable"}#{padTo2Digits @get("now").getUTCMonth() + 1}#{padTo2Digits @get("now").getUTCDate()}_#{padTo2Digits @get("now").getUTCHours()}_0.jpg"
			@accessor "regionLongName", -> $("ul>li[data-value=\"#{@get "region"}\"]>a").text()
			for hour in [3, 9, 15, 21] then do (hour) =>
				@accessor "is#{padTo2Digits hour}Selected", -> @get("now").getUTCHours() is hour
				@accessor "is#{padTo2Digits hour}Enabled", -> if @get("endDate").getUTCHours() >= hour or new Date(@get("endDate")).setUTCHours(0, 0, 0, 0) > new Date(@get("now")).setUTCHours(0, 0, 0, 0) then "" else "disabled"
			for region of latestCARoms then do (region) =>
				@accessor "is_#{region}", -> @get("region") is region
			for variable in ["curr", "salinity", "ssh", "temp"] then do (variable) =>
				@accessor "is_#{variable}", -> !@get("is_drifter") and @get("variable") is variable
			
			constructor: ->
				super

				# Variable is set if queryParam contains one
				if varMap[getParameterByName "variable"]?
					@set "variable", getParameterByName "variable"
				else
					@set "variable", "curr"
				@set "region", "ca" # Default region is set

				# Drifter is set active if queryParam says so
				@set "is_drifter", getParameterByName("drifter") is "active"

				# Setup datepicker and time controls
				now = new Date latestCARoms[@get "region"][@get "variable"]
				$("[data-provide=\"datepicker-inline\"]").datepicker "setStartDate", "04/24/2013"
				$("[data-provide=\"datepicker-inline\"]").datepicker "setEndDate", "#{now.getUTCMonth() + 1}/#{now.getUTCDate()}/#{now.getUTCFullYear()}"
				@set "endDate", now
				@changeNow now
				$("[data-provide=\"datepicker-inline\"]").on "changeDate", (e) =>
					now = new Date @get "now"
					now.setUTCDate e.date.getDate()
					now.setUTCMonth e.date.getMonth()
					now.setUTCFullYear e.date.getFullYear()
					@set "now", now
					now = new Date latestCARoms[@get "region"][@get "variable"]
					@changeNow now if @get("now") > now

				# Set queryParam to current variable/drifter for consistency
				if @get "is_drifter"
					history.replaceState drifter: "active", null, "/ca_roms?drifter=active"
				else
					history.replaceState variable: @get("variable"), null, "/ca_roms?variable=#{@get "variable"}"
				window.onpopstate = (e) =>
					if e.state?.drifter is "active"
						@set "is_drifter", true
					else
						@set "is_drifter", false
						@set "variable", e.state?.variable ? "curr"

			# When an hour is selected for Nowcast
			timeChanged: (node) ->
				now = new Date @get "now"
				now.setUTCHours $(node).attr "data-value"
				@set "now", now

			# Programmatically change imagery date/time
			changeNow: (date) ->
				@set "now", date
				$("[data-provide=\"datepicker-inline\"]").datepicker "update", "#{date.getUTCMonth() + 1}/#{date.getUTCDate()}/#{date.getUTCFullYear()}"
				now = new Date latestCARoms[@get "region"][@get "variable"]
				@changeNow now if @get("now") > now

			# Imagery not found
			imageError: ->
				@set "imageError", true

			# Imagery found
			imageLoad: ->
				@set "imageError", false

			# When a variable is changed using provided tabs/pills
			variableChanged: (node) ->
				if $(node).attr("data-value") is "drifter"
					@set "is_drifter", true
					history.pushState drifter: "active", null, "/ca_roms?drifter=active"
				else
					return if @get("variable") is $(node).attr("data-value") and not @get "is_drifter"
					@set "is_drifter", false
					now = new Date latestCARoms[@get "region"][@get "variable"]
					$("[data-provide=\"datepicker-inline\"]").datepicker "setEndDate", "#{now.getUTCMonth() + 1}/#{now.getUTCDate()}/#{now.getUTCFullYear()}"
					@set "endDate", now
					@set "variable", $(node).attr "data-value"
					@changeNow if @get("now") > now then now else @get("now")
					history.pushState variable: @get("variable"), null, "/ca_roms?variable=#{@get "variable"}"

			# When a region is changed using the dropdown
			regionChanged: (node) ->
				return if @get("region") is $(node).attr "data-value"
				@set "region", $(node).attr "data-value"
				now = new Date latestCARoms[@get "region"][@get "variable"]
				$("[data-provide=\"datepicker-inline\"]").datepicker "setEndDate", "#{now.getUTCMonth() + 1}/#{now.getUTCDate()}/#{now.getUTCFullYear()}"
				@set "endDate", now
				@changeNow if @get("now") > now then now else @get("now")

		# Page Model for HTTP GET '/pws_roms'
		class @::RomsPWSContext extends Batman.Model
			varMap =
				curr: "Current"
				salinity: "Salinity and Current"
				ssh: "Sea Surface Height and Current"
				temp: "Temperature and Current"
			
			# Setup property accessors
			@accessor "imgPath", -> "/data/myocean/PWS-nowcast-l#{@get("rindex")}/images/#{@get("now").getUTCFullYear()}/#{padTo2Digits now.getUTCMonth() + 1}/#{@get "region"}_#{@get "variable"}#{padTo2Digits @get("now").getUTCMonth() + 1}#{padTo2Digits @get("now").getUTCDate()}_#{padTo2Digits @get("now").getUTCHours()}_0.jpg"
			@accessor "regionLongName", -> $("ul>li[data-value=\"#{@get "region"}\"]>a").text()
			for hour in [3, 9, 15, 21] then do (hour) =>
				@accessor "is#{padTo2Digits hour}Selected", -> @get("now").getUTCHours() is hour
				@accessor "is#{padTo2Digits hour}Enabled", -> if @get("endDate").getUTCHours() >= hour or new Date(@get("endDate")).setUTCHours(0, 0, 0, 0) > new Date(@get("now")).setUTCHours(0, 0, 0, 0) then "" else "disabled"
			for region of latestPWSRoms then do (region) =>
				@accessor "is_#{region}", -> @get("region") is region
			for variable in ["curr", "salinity", "ssh", "temp"] then do (variable) =>
				@accessor "is_#{variable}", -> !@get("is_drifter") and @get("variable") is variable
			
			constructor: ->
				super

				# Variable is set if queryParam contains one
				if varMap[getParameterByName "variable"]?
					@set "variable", getParameterByName "variable"
				else
					@set "variable", "curr"
				@set "region", "goa" # Default region is set
				@set "rindex", 0

				# Drifter is set active if queryParam says so
				@set "is_drifter", getParameterByName("drifter") is "active"

				# Setup datepicker and time controls
				now = new Date latestPWSRoms[@get "region"][@get "variable"]
				$("[data-provide=\"datepicker-inline\"]").datepicker "setStartDate", "04/24/2013"
				$("[data-provide=\"datepicker-inline\"]").datepicker "setEndDate", "#{now.getUTCMonth() + 1}/#{now.getUTCDate()}/#{now.getUTCFullYear()}"
				@set "endDate", now
				@changeNow now
				$("[data-provide=\"datepicker-inline\"]").on "changeDate", (e) =>
					now = new Date @get "now"
					now.setUTCDate e.date.getDate()
					now.setUTCMonth e.date.getMonth()
					now.setUTCFullYear e.date.getFullYear()
					@set "now", now
					now = new Date latestPWSRoms[@get "region"][@get "variable"]
					@changeNow now if @get("now") > now

				# Set queryParam to current variable/drifter for consistency
				window.onpopstate = (e) =>
					if e.state?.drifter is "active"
						@set "is_drifter", true
					else
						@set "is_drifter", false
						@set "variable", e.state?.variable ? "curr"

			# When an hour is selected for Nowcast
			timeChanged: (node) ->
				now = new Date @get "now"
				now.setUTCHours $(node).attr "data-value"
				@set "now", now

			# Programmatically change imagery date/time
			changeNow: (date) ->
				@set "now", date
				$("[data-provide=\"datepicker-inline\"]").datepicker "update", "#{date.getUTCMonth() + 1}/#{date.getUTCDate()}/#{date.getUTCFullYear()}"
				now = new Date latestPWSRoms[@get "region"][@get "variable"]
				@changeNow now if @get("now") > now

			# Imagery not found
			imageError: ->
				@set "imageError", true

			# Imagery found
			imageLoad: ->
				@set "imageError", false

			# When a variable is changed using provided tabs/pills
			variableChanged: (node) ->
				return if @get("variable") is $(node).attr("data-value")
				now = new Date latestPWSRoms[@get "region"][@get "variable"]
				$("[data-provide=\"datepicker-inline\"]").datepicker "setEndDate", "#{now.getUTCMonth() + 1}/#{now.getUTCDate()}/#{now.getUTCFullYear()}"
				@set "endDate", now
				@set "variable", $(node).attr "data-value"
				@changeNow if @get("now") > now then now else @get("now")
				history.pushState variable: @get("variable"), null, "/pws_roms?variable=#{@get "variable"}"

			# When a region is changed using the dropdown
			regionChanged: (node) ->
				return if @get("region") is $(node).attr "data-value"
				@set "region", $(node).attr "data-value"
				@set "rindex", $(node).attr "data-rindex"
				now = new Date latestPWSRoms[@get "region"][@get "variable"]
				$("[data-provide=\"datepicker-inline\"]").datepicker "setEndDate", "#{now.getUTCMonth() + 1}/#{now.getUTCDate()}/#{now.getUTCFullYear()}"
				@set "endDate", now
				@changeNow if @get("now") > now then now else @get("now")

		# Page Model for HTTP GET '/interactive'
		class @::InteractiveContext extends Batman.Model
			constructor: ->
				imap = L.map("imap").setView [37.5, -123], 7 # Center map to California region
				(new L.esri.BasemapLayer("Oceans")).addTo imap # Using Esri Oceans Basemap

	# Setup BatmanJS App
	class Rompg extends Batman.App
		@appContext: appContext = new AppContext

	# Start App
	Rompg.run()

	# Executed when page is loaded
	$ ->
		appContext.set "pageLoaded", true # Helper for loading indicator
