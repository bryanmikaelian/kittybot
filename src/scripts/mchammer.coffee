# It's hammer time
#
# hammer - Shows you one of the many (5) successful mc hammer videos / songs

hammertime = [
  "http://www.youtube.com/watch?v=otCpCn0l4Wo",
  "http://www.youtube.com/watch?v=Cdk1gwWH-Cg",
  "http://www.youtube.com/watch?v=1q2TA2zPtac",
  "http://www.youtube.com/watch?v=7xNSgBkum7o",
  "http://www.youtube.com/watch?v=B4qZec7B6oU"
]

module.exports = (robot) ->
  robot.hear /.*(hammer).*/i, (msg) ->
    msg.send msg.random hammertime


