# Gets the number of sounds played
#
# hubot how many <query>? - gets the number of sounds played, based on the query
#

Url   = require "url"
Redis = require "redis"

module.exports = (robot) ->
  info   = Url.parse process.env.REDISTOGO_URL || 'redis://localhost:6379'
  client = Redis.createClient(info.port, info.hostname)

  if info.auth
    client.auth info.auth.split(":")[1]

  robot.respond /(how many rimshots)+\?*/i, (msg) ->
    client.hget "counts", "rimshots", (err, reply) ->
      if err
        throw err
      else if reply is null 
        count = 0
      else
        count = reply
      msg.send "Total rimshots played: #{count}"

  robot.hear /(plays a rimshot)/i, (msg) ->
    client.hincrby "counts", "rimshots", 1, (err, reply) ->
      if err
        throw err

