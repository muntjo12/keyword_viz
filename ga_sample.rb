#!/usr/bin/ruby

require 'rubygems'
require 'garb'

# set email, password, profile_id
Garb::Session.login(email, password)
profile = Garb::Profile.first(profile_id)

report = Garb::Report.new(profile,
        :limit => 100,
        :start_date => Date.today - 30,
        :end_date => Date.today)
report.dimensions :keyword
report.metrics :visits
report.results.each do |result|
  puts "#{result.keyword}:#{result.visits}"
end
