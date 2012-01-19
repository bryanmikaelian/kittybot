# Gets the number of rimshots played
#
# hubot how many rimshots? - gets the number of rimshots played
#

Url   = require "url"
Redis = require "redis"

module.exports = (robot) ->
  info   = Url.parse process.env.REDISTOGO_URL || 'redis://localhost:6379'
  client = Redis.createClient(info.port, info.hostname)

  robot.respond /(how many rimshots)+\?*/i, (msg) ->
    client.hget "counts", "rimshots", (err, reply) ->
      if reply is null 
        count = 0
      else
        count = reply
      msg.send "Total rimshots played: #{count}"
  
  robot.hear /(plays a rimshot)/i, (msg) ->
    client.hincrby "counts", "rimshots", 1, (err, reply) ->
      console.log(err)
