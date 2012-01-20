# Sifter API integration
#
# hubot sifter report - Returns a summary of the open sifter tickets based on the projects.  Regex used so that people can say "what are the open sifters?"
#
#
module.exports = (robot) ->
  robot.respond /sifters/i, (msg)->
    token = process.env.HUBOT_SIFTER_TOKEN || 'cf5b2db69e7ec3019736f299e87f4a60' 
    company = process.env.HUBOT_SIFTER_COMPANY || "fellowshiptech"

    msg.http("https://#{company}.sifterapp.com/api/projects/")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        projects = JSON.parse(body).projects
        msg.send "Generating a report for open issues per project..."
        for project in projects
          msg.http(project.api_issues_url + "?s=1&2")
            .header('X-Sifter-Token', token)
            .header('Accept', 'application/json')
            .get() (err, res, body, project) =>
              @project = project
              issues = JSON.parse(body).issues
              #msg.send @project.name + ": " + issues.length
