# Sifter API integration
#
# hubot give me a sifter report - Returns a summary of the open sifter tickets based on the projects.  Regex used so that people can say "give me a sifters report"
#
# hubot give me a milestone report - Returns a summary of the open sifter tickets for each milestone for each project
#
#

token = process.env.HUBOT_SIFTER_TOKEN
company = process.env.HUBOT_SIFTER_COMPANY

module.exports = (robot) ->
  robot.respond /(give me a )*(sift(e|a)r report)+/i, (msg)->
    msg.send "-- Open issues per project --"
    msg.http("https://#{company}.sifterapp.com/api/projects/")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) ->
        projects = JSON.parse(body).projects
        for project in projects
          do(project) ->
            @project = new Project(project, msg)
            @project.get_total_issues(msg, null)

  robot.respond /(give me a )*(milestone report)+/i, (msg) ->
    msg.send "-- Open issues per milestone --"
    msg.http("https://#{company}.sifterapp.com/api/projects/")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) ->
        projects = JSON.parse(body).projects
        for project in projects
          do(project) ->
            @project = new Project(project, msg)
            @project.get_all_milestone_issues(msg)

class Project 
  constructor: (project, msg) ->
    @name = project.name
    @api_issues_url = project.api_issues_url
    @api_url = project.api_url

  get_total_issues: (msg, milestone) ->
    url = ""
    if milestone is null
      url = "#{@api_issues_url}?s=1-2-3"
    else
      url = "#{milestone.api_issues_url}&s=1-2-3"
    msg.http(url)
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) =>
        data = JSON.parse(body)
        total_pages = data.total_pages
        if total_pages is 1
          if milestone is null
            msg.send "#{@name}: #{data.issues.length}"
          else
            msg.send "#{@name} > #{milestone.name}: #{data.issues.length}" unless data.issues.length is 0
        else
          # Get the last page. Get the length of the issues.  Add 25 for each of the previous pages.
          url = "#{url}&page=#{data.total_pages}&per_page=25"
          msg.http(url)
            .header('X-Sifter-Token', token)
            .header('Accept', 'application/json')
            .header('User-Agent', 'Active Faith Hubot')
            .get() (err, res, body) =>
              data = JSON.parse(body)
              if milestone is null
                msg.send "#{@name}: #{data.issues.length + ((total_pages - 1) * 25)}"
              else 
                msg.send "#{@name} > #{milestone.name}:  #{data.issues.length + ((total_pages - 1) * 25)}" unless data.issues.length is 0

  get_all_milestone_issues: (msg) ->
    milestone_url = "#{@api_url}/milestones/"
    msg.http("#{milestone_url}")
    .header('X-Sifter-Token', token)
    .header('Accept', 'application/json')
    .header('User-Agent', 'Active Faith Hubot')
    .get() (err, res, body) =>
      data = JSON.parse(body)
      unless data.milestones.length is 0
        for milestone in data.milestones
          do(milestone) =>
            unless data.milestones.length is 0
              @get_total_issues(msg, milestone) 

