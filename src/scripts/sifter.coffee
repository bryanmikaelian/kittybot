# Sifter API integration
#
# hubot sifter report - Returns a summary of the open sifter tickets based on the projects.  Regex used so that people can say "what are the open sifters?"
#
#
#
token = process.env.HUBOT_SIFTER_TOKEN || 'cf5b2db69e7ec3019736f299e87f4a60' 
company = process.env.HUBOT_SIFTER_COMPANY || "activefaith"

module.exports = (robot) ->
  robot.respond /sifters/i, (msg)->


    msg.http("https://#{company}.sifterapp.com/api/projects/")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) ->
        projects = JSON.parse(body).projects
        msg.send "Generating a report for open issues per project..."
        for project in projects
          @project = new Project(project)
          @project.get_number_of_issues(msg)

class Project 
  constructor: (project) ->
    @name = project.name
    @api_issues_url = project.api_issues_url 
    @issues = []   

  get_number_of_issues: (msg) ->
    msg.http(@api_issues_url + "?s=1&2&3")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) =>
        issues = JSON.parse(body) 
        next_page = issues.next_page_url
        if issues.total_pages <= 1
          for issue in issues.issues
            @issues.push(new Issue(issue))
          msg.send "#{@name}: #{@issues.length}"
        else
          for x in [1...issues.total_pages]
            for issue in issues.issues
              @issues.push(new Issue(issue))
            msg.send "#{@name}: #{@issues.length}"



class Issue
  constructor: (issue) ->
    @subject = issue.subject 
