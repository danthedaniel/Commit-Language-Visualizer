# read_commits.rb
#
# Usage: read_commits.rb <username> <github api token>
# Read a user's commits and report the time of the commit, the number of lines
# changed, and the language of each file in the commit. Data is sent to stdout
# so that it may be stored as a CSV file or passed into a program capable of
# processing CSV data.

require 'octokit'
require 'linguist'

class VisBlob < Linguist::Blob
  def name
    @path.split('/').last
  end
end

# Determine the language of a given file
def get_lang(client, repo, file)
  blob = VisBlob.new(file.filename, '')
  strategies = [
    Linguist::Strategy::Modeline,
    Linguist::Strategy::Filename,
    Linguist::Strategy::Extension
  ]

  strategies.
    map { |strat| strat.call(blob, nil) }.
    flatten.
    select { |language| not language.color.nil? }.
    first
end

# Calculate stats for an event on the user's timeline
def event_stats(client, event)
  repo = client.repository(event[:repo][:name])
  event[:payload][:commits].each do |commit|
    commit_stats(client, repo, commit, event.created_at)
  end
end

# Calculate stats for a specific commit within an event
def commit_stats(client, repo, commit, timestamp)
  client.commit(repo.full_name, commit.sha).files.each do |file|
    lang = get_lang(client, repo, file)

    unless lang.nil?
      puts [lang.color, timestamp.to_i, file.changes].join ','
    end
  end
end

# Run through all commits available
def analyze_commits(user, token)
  begin
    client = Octokit::Client.new(access_token: token)

    events = client.user_events(user)
    events.
      select { |event| event[:type] == 'PushEvent' }.
      map { |event| event_stats(client, event) }
  rescue Interrupt
  end
end

Octokit.auto_paginate = true
analyze_commits(ARGV[0], ARGV[1])
