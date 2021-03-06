#!/usr/bin/env ruby

require 'time'
require 'date'
require 'URI'

def chart_commits
  lines = `git log --pretty=format:%ai`
  times = lines.map { |l| Time.parse l }

  dots = []
  0.upto(7) { |wday|
    0.upto(23) { |hour|
      dots &lt;&lt; [hour, wday, times.find_all { |t| t.hour == hour &amp;&amp; t.wday == wday }.size]
    }
  }
  
  max = dots.map { |h,w,c| c }.max

  title = "Commit Activity by Day and Hour"

  url = "http://chart.apis.google.com/chart?chtt=#{title}&amp;chs=800x350&amp;chds=-1,24,-1,7,0,#{max}&amp;chf=bg,s,efefef&amp;chd=t:#{dots.transpose.map { |c| c.join(",") }.join("|")}&amp;chxt=x,y&amp;chm=o,333333,1,1.0,25.0&amp;chxl=0:||12am|1|2|3|4|5|6|7|8|9|10|11|12pm|1|2|3|4|5|6|7|8|9|10|11||1:||Sun|Mon|Tue|Wed|Thr|Fri|Sat|&amp;cht=s&amp;chma=20,20,20,20"

  out = URI.escape(url)
  
  return out
end

def chart_authors
  author_limit = 10
  authors = _get_authors

  c = Hash.new(0)
  authors.each { |n| c[n] += 1 }
  c = c.sort_by { |x| x[1] }.reverse

  if c.count &lt; author_limit
    limit = c.count
    title = "Commits by Authors"
  else
    limit = author_limit
    title = "Commits by Top " + limit.to_s + " Authors"
  end

  max = c.map { |n, x| x  }.max

  values = []
  authors = []

  c.each { |n, c| values &lt;&lt; c &amp;&amp; authors &lt;&lt; n + ' (' + c.to_s + ')' }

  values = values[0..limit-1].join(',')
  authors = authors[0..limit-1].join('|')

  url = "http://chart.apis.google.com/chart?chtt=#{title}&amp;chs=800x350&amp;cht=p&amp;chds=0,#{max}&amp;chd=t:#{values}&amp;chl=#{authors}&amp;chdlp=l&amp;chp=360&amp;chma=20,20,20,20"

  out = URI.escape(url)
  return out

end

def chart_timeline
  lines = `git log --pretty=format:%ai`
  times = lines.map { |l| Date.parse l }

  days_limit = 90
  date_range = ( DateTime.now - (times[-1]) ).to_i
  dl = ( date_range &lt; days_limit ? date_range : days_limit )

  dates = Hash.new(0)
  ( (times[0]-dl+1) .. DateTime.now ).each { |d| 
    dates[d] = times.find_all{ |t| t.to_s == d.to_s }.size
  }
  dates = dates.sort
  
  max = dates.map { |n, x| x  }.max + 10
  max = max - ( max % 10 )

  marks = []
  (0..dates.count).step(10) { |d| marks &lt;&lt; [ d, dates[d][0] ] }
  marks[-1][1] = dates[-1][0]
  marks_str = '|' + marks.map { |k, v| "#{v}" }.join("|")
  marks_step = '|' + marks.map { |k, v| "#{k}" }.join("|")

  chart_data = dates.map! { |k, v| "#{v}" }.join(",")

  gc = Hash[[
    ["cht", "lc"],
    ["chs", "800x350"],
    ["chtt", "Commit Activity over the last #{dl.to_s} Days"],
    ["chxl", "0:#{marks_str}"],
    ["chxp", marks_step],
    ["chxr", "0,0,#{dates.count}|1,0,#{max}"],
    ["chxtc", "0,10|1,5"],
    ["chxt", "x,y"],
    ["chma", "20,20,20,20"],
    ["chco", "3D7930,FF9900"],
    ["chds", "0,#{max}"],
    ["chd", "t:#{chart_data}"],
    ["chxl", "0:#{marks_str}"],
    ["chxr", "0,0,#{dates.count}|1,0,#{max}"],
    ["chxp", "#{marks_step}"],
    ["chg", "-1,-1,0,0"],
  ]]

  return URI.escape( "http://chart.apis.google.com/chart?" + gc.sort.map! { |k, v| "#{k}=#{v}" }.join("&amp;") )
  
end

def _get_authors
  lines = `git log --pretty=format:%an`
  authors = lines.map { |l| l.strip }
  return authors
end

puts '<!DOCTYPE html><html lang="en"><head><title>Git Charts</title><style type="text/css" media="screen">body{margin: 20px;padding: 0px;}img{margin: 0 0 10px;}</style></head><body>'
puts '<img src="'+chart_commits+'" />'
puts '<img src="'+chart_timeline+'" />'
puts '<img src="'+chart_authors+'" />'
puts '</body></html>'