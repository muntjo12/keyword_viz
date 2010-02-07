#!/usr/bin/ruby

require 'rubygems'
require 'garb'

# set email, password, profile_id
Garb::Session.login(email, password)
profile = Garb::Profile.first(profile_id)

report_results = []
from = Date.civil(2008, 1, 1)
to = from >> 1 

while to < Date.today
  report = Garb::Report.new(profile,
    :limit => 10000,
    :start_date => from,
    :end_date => to)
  report.dimensions :keyword
  report.metrics :visits
  results = report.results || {}
  data = []
  results.each { |result| data.push(result.keyword) if result.visits.to_i > 0 }
  data.delete('(not set)')
  report_result = {
    'range' => from.strftime("%m/%y"),
    'data'  => data,
    'size'  => data.size.to_s
  }
  report_results.push(report_result)
  from = to
  to = to >> 1
end

# raw_data_file: raw keyword data
# count_file: unique keyword sums
raw_data_file = File.new('raw_data.txt', 'wb')
count_file = File.new('counts.txt', 'wb')
report_results.each do |report_result|
  raw_data_file.puts 'Month: ' + report_result['range'] + "\nSize: " + report_result['size']
  count_file.puts report_result['range'] + "," + report_result['size']
  report_result['data'].sort.each { |key, value| raw_data_file.puts key }
end
raw_data_file.close
count_file.close

# venn_file: google chart api URLs for monthly keyword overlap
venn_file = File.new('venn.txt', 'wb')
for i in 0..(report_results.length - 2) do
  report_result = report_results[i]
  inner_report_result = report_results[i+1]
    count = (inner_report_result['data'] & report_result['data']).size
    count_inner = (inner_report_result['data'] - report_result['data']).size
    count_outer = (report_result['data'] - inner_report_result['data']).size
    max = [count, count_outer, count_inner].max
    if max > 0
      scale_factor = 100/max.to_f
      count = scale_factor * count 
      count_outer = scale_factor * count_outer
      count_inner = scale_factor * count_inner
    end
    date_label = count_outer <= count_inner ? report_result['range'] + '|' + inner_report_result['range'] : inner_report_result['range'] + '|' + report_result['range']
    venn_file.puts 'http://chart.apis.google.com/chart?cht=v&chd=t:' + count_outer.to_i.to_s + ',' + count_inner.to_i.to_s + ',0,' + count.to_i.to_s + ',0,0&chs=250x100&chl=' + date_label
end
venn_file.close
