#!/usr/bin/env ruby

desc = <<EOD

 Ingests the posts and creates a posts.json file 
 representing the image content, does NOT delete the feeds.

 You should pass the /logs endpoint to this script for instance

 ./log-digest somesite.tumblr.com/logs

 After this is done you should see a */logs/posts.json file
EOD

require 'rubygems'
require 'bundler'
Bundler.require

$start = Time.new

if ARGV.length == 0
  print desc
  exit
end

Dir.chdir(ARGV[0])
logList = Dir.glob("*") 

def parsefile(doc)
  Hash[
    (doc/'post').map { | post |
      [
        post['url'].to_s.split('/').pop, 
        [
          # thumbnail
          (post/'photo-url').select { | x | x['max-width'].to_i == 100 }.map { | x | x.content.to_s  },

          # large
          (post/'photo-url').select { | x | x['max-width'].to_i == 1280 }.map { | x | x.content.to_s  }
        ]
      ]
    }
  ]
end

lastLog = nil
lastCreated = nil
logList.each { | file |
  if file == 'posts.json'
    lastCreated = File.stat(file).ctime 
    next
  end

  lastLog = File.stat(file).ctime if lastLog.nil?
  lastLog = [File.stat(file).ctime, lastLog].max
  
  unless lastCreated.nil?
    break if lastLog > lastCreated 
  end
}

if lastLog.nil?
  puts "  >>>  ??? #{ARGV[0]}"
  exit
end

total = logList.length

if lastCreated.nil? or lastLog > lastCreated
  hash = {}
  logList.each { | file |
      next if file == 'badurl' or file == 'posts.json'

      File.open(file, 'r') { | content |
        hash.merge! parsefile Nokogiri::XML.parse(content)
      }
  }

  File.open('posts.json', 'w') { | f |
    f << hash.to_json
  }
  duration = Time.new - $start

  puts "(#{(total / duration).to_i}) #{duration} #{ARGV[0]}" 
else
  puts "N/A #{ARGV[0]}"
end
