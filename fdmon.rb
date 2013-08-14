#!/usr/bin/env ruby
#
# Consider this application a "top" for watching file descriptors for
# an indicated process ID.  This is handy sometimes if a program
# doesn't tell you what it's doing with its descriptors.  For example,
# I had a program that would not tell me the current status of an
# upload.  By watching as the I/O FDs approached 100%, I could monitor
# its progress.
#
# All of the data comes from /proc.  The user running the program
# needs to have the right permissions to read information for the
# target PIDs /proc content.
#
# Author:  Josh Stone
# Date:    2013-08-13
# Contact: yakovdk@gmail.com
#
#


$yellow = "\e[33;1m"
$blue   = "\e[34;1m"
$red    = "\e[31;1m"
$reset  = "\e[0m"

class Descriptor
  attr_accessor :num, :target, :size, :pos

  #
  # Given a PID and a numeric file descriptor, grab all of the
  # necessary data to represent this file descriptor.
  #

  def initialize(pid, fd)
    @num = fd
    begin
      @target = File.readlink("/proc/#{pid}/fd/#{fd}")
    rescue
      @target = "unknown"
    end
    @size   = File.exists?(@target) ? File.size(@target) : 0
    @pos = File.read("/proc/#{pid}/fdinfo/#{@num}").split(/\n/)[0].split(/\t/)[1].to_i
  end

  #
  # If we have a size and position, we can calculate the current
  # location (or "progress") in reading the file descriptor.  For
  # random access, this should hop around, but for some process that
  # is gradually processing a file, this should work well as a
  # percent-completed indicator.
  #

  def prog
    return @size > 0 ? 100.0 * @pos / @size : 0.0
  end

  #
  # Makes a relatively pretty "bar graph" showing the current position
  # of the file descriptor.  This comes out as a yellow bar on a blue
  # "background" of hyphens.
  #

  def meter
    p = prog
    ret = ("-" * 10) 
    mark  = (p/10.1).round
    ret[(p/11).round] = ">#{$blue}"
    0.upto(mark-1) {|i| ret[i] = "="}
    return $yellow + ret + $reset
  end
end

def banner
  system("clear")
  puts ""
  puts "Josh's Process #{$red}F#{$reset}ile #{$red}D#{$reset}escriptor #{$red}Mon#{$reset}itor (#{$red}fdmon#{$reset})"
  puts "yakovdk@gmail.com (http://github.com/jephthai/fdmon)"
  puts ""
  puts "Monitoring PID #{$blue}#{pid}#{$reset}, '#{$blue}#{com} #{arg[0..60]}#{$reset}'"
  puts ""
  printf("#{$red} %6s%% %-10s %-5s %-15s %-15s    %s#{$reset}\n\n",
         "PROG", "METER", "FD", "POS", "SIZE", "FILE")
end

#
# When we invoke this script as a command, we receive a PID as an
# argument and regularly update a display of FD information.  It's
# kind of like "top".
#

if $0 == __FILE__
  
  if(ARGV.length != 1)
    puts "usage: pswatch.rb <pid>"
    exit(1)
  end

  pid = ARGV[0]
  com = File.read("/proc/#{pid}/comm").strip
  arg = File.read("/proc/#{pid}/cmdline").split(/\x00/)[1..-1].join(" ")

  while true
    fds = []
    Dir.new("/proc/#{pid}/fd").each do |entry|
      fds << Descriptor.new(pid,entry) unless [".", ".."].member? entry
    end
    banner
    fds.each do |fd|
      printf(" %6.2f%% %-10s %-5d %-15d %-15d    %s\n",
             fd.prog, fd.meter, fd.num, fd.pos, fd.size, File.basename(fd.target))
    end
    sleep 0.5
  end
end
