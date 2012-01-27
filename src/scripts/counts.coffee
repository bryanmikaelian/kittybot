# Gets the number of sounds played
#
# hubot how many <query>? - gets the number of sounds played, based on the query
#

Url   = require "url"
Redis = require "redis"

rimshot_responses = [
  "Rimshot noted. +1",
  "Who played that rimshot? +1",
  "Plays the rimshot. And boom goes the dynamite. +1",
  "Just like Back to the Future 3. Rimshot +1",
  "Hi Scott. Rimshot +1",
  "Now my ears are bleeding from that rimshot. +1",
  "Make sense? Rimshot +1",
  "Everybody walk the dinosaur. Rimshot +1",
  "....",
  "Show me potato salad! Rimshot +1",
  "Rimshot backwards is Tohsmir. +1",
  "Rimshot count updated. +1",
  "This +1 rimshot goes out to my friend Kingsley Allen.  Big fan of his work.",
  "Rimshots.  Rimshots everywhere. +1",
  "Stop play those rimshots...right meow. +1",
  "Afraid not. Rimshot +1"
]

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

  robot.rimshot (msg) ->
    client.hincrby "counts", "rimshots", 1, (err, reply) ->
      if err
        throw err
      else
        msg.send msg.random rimshot_responses

