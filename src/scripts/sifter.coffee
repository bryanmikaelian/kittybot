# Sifter API integration
#
# sifters - Returns a list of the open sifter tickets.  Regex used so that people can say "what are the open sifters?"
#
#
module.exports = (robot) ->
  robot.hear /sifters/, (msg)->
    # TODO: Add sifter logic here
