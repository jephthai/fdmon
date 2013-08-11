#!/usr/bin/env ruby

yellow = "\e[33;1m"
blue   = "\e[34;1m"
red    = "\e[31;1m"
reset  = "\e[0m"

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
    fds << entry unless [".", ".."].member? entry
  end

  files = fds.map do |fd|
    begin
      File.readlink("/proc/#{pid}/fd/#{fd}")
    rescue 
      "unknown"
    end
  end

  sizes = files.map do |file|
    if file == "unknown" || !(File.exists? file)
      -1
    else
      File.size(file)
    end
  end

  pos = fds.map do |fd|
    File.read("/proc/#{pid}/fdinfo/#{fd}").split(/\n/)[0].split(/\t/)[1].to_i
  end

  system("clear")

  puts ""
  puts "Josh's Process #{red}F#{reset}ile #{red}D#{reset}escriptor #{red}Mon#{reset}itor (#{red}fdmon#{reset})"
  puts "yakovdk@gmail.com (http://github.com/jephthai/fdmon)"
  puts ""
  puts "Monitoring PID #{blue}#{pid}#{reset}, '#{blue}#{com} #{arg[0..60]}#{reset}'"
  puts ""

  printf("#{red} %6s%% %-10s %-5s %-15s %-15s    %s#{reset}\n",
         "PROG", "METER", "FD", "POS", "SIZE", "FILE")
  puts ""

  0.upto(fds.length-1).each do |fd|
    unless pos[fd] == 0 and sizes[fd] == 0
      prog = sizes[fd] > 0 ? 100.0 * pos[fd] / sizes[fd] : 0.0
      meter = ("-" * 10) 
      mark = (prog/10.1).round
      meter[(prog/11).round] = ">#{blue}"
      0.upto(mark-1) {|i| meter[i] = "="}
      meter = yellow + meter + reset
      printf(" %6.2f%% %-10s %-5d %-15d %-15d    %s\n",
             prog, meter, fds[fd], pos[fd], sizes[fd], File.basename(files[fd]))
    end
  end

  sleep 0.25
end
