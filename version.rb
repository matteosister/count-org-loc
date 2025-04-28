# frozen_string_literal: true

require 'octokit'
require 'open3'
require 'cliver'
require 'fileutils'
require 'dotenv'
require 'csv'

if ARGV.count != 1
  puts 'Usage: script/count [ORG NAME]'
  exit 1
end

Dotenv.load

def cloc(*args)
  cloc_path = Cliver.detect! 'cloc'
  Open3.capture2e(cloc_path, *args)
end

tmp_dir = File.expand_path './tmp', File.dirname(__FILE__)
FileUtils.rm_rf tmp_dir
FileUtils.mkdir_p tmp_dir

# Enabling support for GitHub Enterprise
unless ENV['GITHUB_ENTERPRISE_URL'].nil?
  Octokit.configure do |c|
    c.api_endpoint = ENV['GITHUB_ENTERPRISE_URL']
  end
end

client = Octokit::Client.new access_token: ENV['GITHUB_TOKEN']
client.auto_paginate = true

begin
  repos = client.organization_repositories(ARGV[0].strip, type: 'sources')
rescue StandardError
  repos = client.repositories(ARGV[0].strip, type: 'sources')
end
puts "Found #{repos.count} repos. Counting..."

includes = []
CSV.foreach("script/include.csv") do |row|
  # Process each row, in this example, print A summary of fields,
  # by header, in an ASCII compatible String.
  includes << row[0]
end

repos.each do |repo|
  unless includes.include?(repo.name)
    next
  end
  puts "Counting #{repo.name}..."

  destination = File.expand_path repo.name, tmp_dir

  clone_url = repo.clone_url
  clone_url = clone_url.sub '//', "//#{ENV['GITHUB_TOKEN']}:x-oauth-basic@" if ENV['GITHUB_TOKEN']
  _output, status = Open3.capture2e 'git', 'clone', '--depth', '1', '--quiet', clone_url, destination
  next unless status.exitstatus.zero?

  if File.file?("#{destination}/Dockerfile") do |_file|

  end
end
