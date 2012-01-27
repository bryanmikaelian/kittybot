module.exports = (robot) ->
  robot.respond /(add my phone)+( number)?( [0-9\-]*)/i, (msg) ->
    
    msg.send "#{msg.message.user.name}, I have added your phone number to the rolodex"
