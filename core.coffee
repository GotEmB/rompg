###
	Author: Gautham Badhrinathan (gotemb@ucla.edu)
	Functions used in `web.coffee`.
###

fs = require "fs"

# Pad Digits. Ex. 1 -> 01; 10 -> 10
padTo2Digits = (n) -> if n < 10 then "0" + n else n

# Will contain metadata on available ROMS
latestRoms = undefined

# Function called in `web.coffee`
exports.getLatestROMS = ->
	latestRoms

# Checks for the lastest image for region-variable pair backward from today till Jan 1, 2012
exports.updateLatestRoms = ->
	latestRoms = {}
	for region in ["ca", "cc", "ccc", "mb", "sfb", "nc1", "nc2", "scb"]
		for variable in ["curr", "salinity", "ssh", "temp"]
			now = new Date
			now.setDate now.getDate() - 1 if Math.floor((now.getUTCHours() - 3) / 6) < 0
			now.setUTCHours ((Math.floor (now.getUTCHours() - 3) / 6 + 4) % 4) * 6 + 3
			now.setUTCMinutes 0
			now.setUTCSeconds 0
			now.setUTCMilliseconds 0
			until now.getUTCFullYear() is 2012 or fs.existsSync "#{process.env.CAROMS_DIR}/#{now.getUTCFullYear()}/#{now.getUTCMonth() + 1}/#{region}_#{variable}#{padTo2Digits now.getUTCMonth() + 1}#{padTo2Digits now.getUTCDate()}_#{padTo2Digits now.getUTCHours()}_0.jpg"
				now = new Date now - 6 * 60 * 60 * 1000
			now = null if now.getUTCFullYear() is 2012
			if now?
				latestRoms[region] ?= {}
				latestRoms[region][variable] = now

# Returns a list of regions for which Nowcast Imagery are available
exports.getAvailableRegions = ->
	regionMap =
		ca: "California"
		cc: "Central and Northern California"
		ccc: "Central California"
		mb: "Monterey Bay"
		sfb: "San Francisco Bay"
		nc1: "North Coast I"
		nc2: "North Coast II"
		scb: "Southern California"
	latestRoms = exports.getLatestROMS()
	ret = []
	for shortCode, longName of regionMap
		ret.push shortCode: shortCode, longName: longName if latestRoms[shortCode]?
	ret

do ->
	# Run `updateLatestRoms` on startup and every hour afterwards
	exports.updateLatestRoms()
	setInterval exports.updateLatestRoms, 60 * 60 * 1000
