Url   = require "url"
Redis = require "redis"

info   = Url.parse process.env.REDISTOGO_URL || 'redis://localhost:6379'
client = Redis.createClient(info.port, info.hostname)

if info.auth
  client.auth info.auth.split(":")[1]

module.exports = (robot) ->
  robot.respond /(add my phone)+( number )?([0-9\-]*)/i, (msg) -> 
    phone_regex = /(add my phone )+(number)?/i
    phone = msg.message.text.replace phone_regex, ""
    phone = phone.replace robot.name, ""
    phone = "Phone:#{phone}"
    client.hset msg.message.user.name, "Phone", phone, (err, reply) ->
      if err
        console.log err
      else
        msg.send "#{msg.message.user.name}, I have added your phone number to the rolodex."

  robot.respond /(get contact info for )+([a-zA-Z])+\ ?([a-zA-Z])+/i, (msg) ->
    name = msg.message.text.replace /(get contact info for )+/i, ""
    name = name.replace robot.name, ""
    msg.send name
    msg.send "Getting the info"
