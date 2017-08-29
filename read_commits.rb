require 'octokit'
require 'linguist'

class VisBlob < Linguist::Blob
  def name
    @path.split('/').last
  end
end

def get_lang(client, repo, file)
  content = client.get file[:raw_url]
  blob = VisBlob.new(file[:filename], content)
  languages = client.languages(repo[:full_name]).to_h.keys.map do |lang|
    Linguist::Language.find_by_name(lang.to_s)
  end

  if languages.length > 0
    begin
      Linguist::Classifier.call(blob, languages).first
    rescue NoMethodError
    end
  end
end

def event_stats(client, event)
  repo = client.repository(event[:repo][:name])
  event[:payload][:commits].map do |commit|
    commit_stats(client, repo, commit, event[:created_at])
  end
end

def commit_stats(client, repo, commit, timestamp)
  client.commit(repo[:full_name], commit[:sha])[:files].map do |file|
    lang = get_lang(client, repo, file)

    unless lang.nil?
      puts [lang.name, timestamp.to_i, file[:changes]].join ','
    end
  end
end

def analyze_commits(user, token)
  client = Octokit::Client.new(access_token: token)

  events = client.user_events(user)
  events.
    select { |event| event[:type] == 'PushEvent' }.
    map { |event| event_stats(client, event) }
end

Octokit.auto_paginate = true
analyze_commits(ARGV[0], ARGV[1])
