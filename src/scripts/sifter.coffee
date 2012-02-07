# Sifter API integration
#
# hubot give me a sifter report - Returns a summary of the open sifter tickets based on the projects.  Regex used so that people can say "give me a sifters report"
#
# hubot give me a milestone report - Returns a summary of the open sifter tickets for each milestone for each project
#
#

token = process.env.HUBOT_SIFTER_TOKEN
company = process.env.HUBOT_SIFTER_COMPANY
Url   = require "url"
Redis = require "redis"
http = require 'scoped-http-client'

info   = Url.parse process.env.REDISTOGO_URL || 'redis://localhost:6379'
client = Redis.createClient(info.port, info.hostname)

if info.auth
  client.auth info.auth.split(":")[1]


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
            @project.get_total_issues(msg, null, null)

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

  # Sifter Polling - Active Network Faith specific - QA Environment 
  robot.timestamp (msg) ->
    msg.http("https://#{company}.sifterapp.com/api/projects/")
    .header('X-Sifter-Token', token)
    .header('Accept', 'application/json')
    .header('User-Agent', 'Active Faith Hubot')
    .get() (err, res, body) ->
      projects = JSON.parse(body).projects
      for project in projects
        do(project) ->
          @project = new Project(project, msg)
          @project.get_all_change_requests_qa(msg)
          @project.get_all_change_requests_staging(msg)
          if project.name is "Faith | IRV | Fellowship One"
            @project.get_all_issues_for_f1(msg)

class Project 
  constructor: (project, msg) ->
    @name = project.name
    @api_issues_url = project.api_issues_url
    @api_url = project.api_url

  get_total_issues: (msg, milestone, category) ->
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
          if milestone is null and category is null
            msg.send "#{@name}: #{data.issues.length}"
          else if category is null
            msg.send "#{@name} > #{milestone.name}: #{data.issues.length}" unless data.issues.length is 0
          else 
            msg.send "#{@name} > #{category.name}: #{data.issues.length}" unless data.issues.length is 0
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
              @get_total_issues(msg, milestone, null) 

  # Active Network - Faith Specific
  get_all_change_requests_qa: (msg) ->
    category_number_regex = /https:\/\/activefaith.sifterapp.com\/projects\/[0-9]*\/issues\?/i
    category_disposition_regex = /(Dropped \| QA)+/i
    change_request_regex = /(Change Request)+(\-[A-Z]*)*( for Deployment of )+/i
    msg.http("#{@api_url}/categories")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) =>
        data = JSON.parse(body)
        for category in data.categories
          do(category) ->
            if category_disposition_regex.test category.name
              msg.http("#{category.api_issues_url}&s=1-2-3")
              .header('X-Sifter-Token', token)
              .header('Accept', 'application/json')
              .header('User-Agent', 'Active Faith Hubot')
              .get() (err, res, body) =>
                data = JSON.parse(body)
                for issue in data.issues
                  do(issue) ->
                    build = issue.subject.replace change_request_regex, ""
                    client.sismember "qa_builds", build, (error, reply) ->
                      if reply is 0
                        console.log "Adding #{build} to qa_builds hash"
                        client.sadd "qa_builds", build, (error, reply) ->
                          msg.send "#{build} has just been deployed to QA"

  # Active Network - Faith Specific
  get_all_change_requests_staging: (msg) ->
    category_number_regex = /https:\/\/activefaith.sifterapp.com\/projects\/[0-9]*\/issues\?/i
    category_disposition_regex = /(Dropped \| Staging)+/i
    change_request_regex = /(Change Request)+(\-[A-Z]*)*( for Deployment of )+/i
    msg.http("#{@api_url}/categories")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) =>
        data = JSON.parse(body)
        for category in data.categories
          do(category) ->
            if category_disposition_regex.test category.name
              msg.http("#{category.api_issues_url}&s=1-2-3")
              .header('X-Sifter-Token', token)
              .header('Accept', 'application/json')
              .header('User-Agent', 'Active Faith Hubot')
              .get() (err, res, body) =>
                data = JSON.parse(body)
                for issue in data.issues
                  do(issue) ->
                    build = issue.subject.replace change_request_regex, ""
                    client.sismember "staging_builds", build, (error, reply) ->
                      if reply is 0
                        console.log "Adding #{build} to staging_builds hash"
                        client.sadd "staging_builds", build, (error, reply) ->
                          msg.send "#{build} has just been deployed to Staging"

  get_all_issues_for_f1: (msg) ->
    msg.http("#{@api_issues_url}?s=1-2-3")
      .header('X-Sifter-Token', token)
      .header('Accept', 'application/json')
      .header('User-Agent', 'Active Faith Hubot')
      .get() (err, res, body) =>
        data = JSON.parse(body)
        for issue in data.issues
          do (issue) ->
            client.sismember "open_issues", issue.number, (error, reply) ->
              if reply is 0
                console.log "Adding #{issue.number} to the open issues set"
                client.sadd "open_issues", issue.number, (error, reply) ->
                  msg.send "#{issue.opener_name} has opened Sifter ##{issue.number}: #{issue.subject}"
