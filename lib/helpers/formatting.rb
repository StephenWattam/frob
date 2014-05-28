

require 'time'
require 'github/markdown'

module Formatting 

  # Boolean type
  def bln(val)
    val ? 'True' : 'False'
  end

  # Output datetime
  def dtm(time)
    return '' unless time
    time = Time.at(time.to_i) if time.is_a?(Numeric)
	  fmt = "%d %b %y - %H:%M:%S"
	  fmt += " %z" unless time.strftime("%z") == '+0000'
	  time.strftime(fmt)
  end

  # Output duration
  #
  # Ugly as hell, but doesn't require libraries.
  # Thanks to http://stackoverflow.com/questions/1679266/can-ruby-print-out-time-difference-duration-readily
  def dur(time)
    return '' unless time && time.is_a?(Numeric) && time > 0
	  
    secs  = time.to_int
	  mins  = secs / 60
	  hours = mins / 60
	  days  = hours / 24
	
	  if days > 0
	    "#{days} #{pl('day', days)} and #{hours % 24} #{pl('hour', hours)}"
	  elsif hours > 0
	    "#{hours} #{pl('hour', hours)} and #{mins % 60} #{pl('minute', mins)}"
	  elsif mins > 0
	    "#{mins} #{pl('minute', mins)} and #{secs % 60} #{pl('second', secs)}"
	  elsif secs >= 0
	    "#{secs} #{pl('second', secs)}"
	  end
  end


  # Output duration
  #
  # Ugly as hell, but doesn't require libraries.
  # Thanks to http://stackoverflow.com/questions/1679266/can-ruby-print-out-time-difference-duration-readily
  def dur_short(time)
    return '' unless time && time.is_a?(Numeric) && time > 0
	  
    secs  = time.to_int
	  mins  = secs / 60
	  hours = mins / 60
	  days  = hours / 24
	
	  if days > 0
	    "#{days} #{pl('day', days)}, #{hours % 24} #{pl('hr', hours)}"
	  elsif hours > 0
	    "#{hours} #{pl('hr', hours)}, #{mins % 60} #{pl('min', mins)}"
	  elsif mins > 0
	    "#{mins} #{pl('min', mins)}, #{secs % 60} #{pl('sec', secs)}"
	  elsif secs >= 0
	    "#{secs} #{pl('sec', secs)}"
	  end
  end


  # Filesize
  def f(bytes, binary = false)
    bytes ||= 0
    b = binary ? 1024 : 1000
    units = ([''] + %w{K M G T Y E Z Y}).map{|x| "#{x}#{binary ? 'i' : ''}B"}
    e = (bytes > 0) ? (Math.log(bytes)/Math.log(b)).floor : 0
    s = "%.2f" % (bytes.to_f / b**e)
    s.sub(/\.?0*$/, units[e])
  end

  # Markdown
  def md(string)
    GitHub::Markdown::render_gfm(string.to_s)
  end

  # Plural
  def pl(string, number = 0)
    string = string.to_s
    return string if number == 1

    return case string[-1]
           when 'y' && 'aeiou'.chars.include?(string[-2].to_s.downcase)
             "#{string[0..-2]}ies"
           else
             "#{string}s"
           end
  end

  # TODO: time, date, filesize, number
end

