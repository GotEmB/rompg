###
	Author: Gautham Badhrinathan (gotemb@ucla.edu)
	Functions used in `web.coffee`.
###

fs = require "fs"

# Pad Digits. Ex. 1 -> 01; 10 -> 10
padTo2Digits = (n) -> if n < 10 then "0" + n else n

###
	CA Roms
###

# Will contain metadata on available Roms
latestCARoms = undefined

# Function called in `web.coffee`
exports.getLatestCARoms = ->
	latestCARoms

# Checks for the lastest image for region-variable pair backward from today till Jan 1, 2012
exports.updateLatestCARoms = ->
	latestCARoms = {}
	for region in ["ca", "cc", "ccc", "mb", "sfb", "nc1", "nc2", "scb"]
		for variable in ["curr", "salinity", "ssh", "temp"]
			now = new Date
			now.setDate now.getDate() - 1 if Math.floor((now.getUTCHours() - 3) / 6) < 0
			now.setUTCHours ((Math.floor (now.getUTCHours() - 3) / 6 + 4) % 4) * 6 + 3
			now.setUTCMinutes 0
			now.setUTCSeconds 0
			now.setUTCMilliseconds 0
			until now.getUTCFullYear() is 2012 or fs.existsSync "sampledata/#{now.getUTCFullYear()}/#{region}_#{variable}#{padTo2Digits now.getUTCMonth() + 1}#{padTo2Digits now.getUTCDate()}_#{padTo2Digits now.getUTCHours()}_0.jpg"
				now = new Date now - 6 * 60 * 60 * 1000
			now = null if now.getUTCFullYear() is 2012
			if now?
				latestCARoms[region] ?= {}
				latestCARoms[region][variable] = now

# Returns a list of regions for which Nowcast Imagery are available
exports.getAvailableCARegions = ->
	regionMap =
		ca: "California"
		cc: "Central and Northern California"
		ccc: "Central California"
		mb: "Monterey Bay"
		sfb: "San Francisco Bay"
		nc1: "North Coast I"
		nc2: "North Coast II"
		scb: "Southern California"
	latestCARoms = exports.getLatestCARoms()
	ret = []
	for shortCode, longName of regionMap
		ret.push shortCode: shortCode, longName: longName if latestCARoms[shortCode]?
	ret

###
	PWS Roms
###

# Will contain metadata on available Roms
latestPWSRoms = undefined

# Function called in `web.coffee`
exports.getLatestPWSRoms = ->
	latestPWSRoms

# Checks for the lastest image for region-variable pair backward from today till Jan 1, 2012
exports.updateLatestPWSRoms = ->
	latestPWSRoms = {}
	for region, ri in ["goa", "ngoa", "pws"]
		for variable in ["curr", "salinity", "ssh", "temp"]
			now = new Date
			now.setDate now.getDate() - 1 if Math.floor((now.getUTCHours()) / 6) < 0
			now.setUTCHours ((Math.floor (now.getUTCHours()) / 6 + 4) % 4) * 6
			now.setUTCMinutes 0
			now.setUTCSeconds 0
			now.setUTCMilliseconds 0
			until now.getUTCFullYear() is 2012 or fs.existsSync "#{process.env.MYOCEAN_DIR}/PWS-nowcast-l#{ri}/images/#{now.getUTCFullYear()}/#{padTo2Digits now.getUTCMonth() + 1}/#{region}_#{variable}#{padTo2Digits now.getUTCMonth() + 1}#{padTo2Digits now.getUTCDate()}_#{padTo2Digits now.getUTCHours()}_0.jpg"
				now = new Date now - 6 * 60 * 60 * 1000
			now = null if now.getUTCFullYear() is 2012
			if now?
				latestPWSRoms[region] ?= {}
				latestPWSRoms[region][variable] = now

# Returns a list of regions for which Nowcast Imagery are available
exports.getAvailablePWSRegions = ->
	regionMap =
		goa: "Gulf of Alaska"
		ngoa: "Northeast Gulf of Alaska"
		pws: "Prince William Sound"
	latestPWSRoms = exports.getLatestPWSRoms()
	ret = []
	rindex = 0
	for shortCode, longName of regionMap
		ret.push shortCode: shortCode, longName: longName, rindex: rindex if latestPWSRoms[shortCode]?
		rindex++
	ret

do ->
	# Run `updateLatestRoms` on startup and every hour afterwards
	exports.updateLatestCARoms()
	setInterval exports.updateLatestCARoms, 60 * 60 * 1000
	exports.updateLatestPWSRoms()
	setInterval exports.updateLatestPWSRoms, 60 * 60 * 1000