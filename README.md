fdmon
=====

This tool is useful for watching what a process is doing with its file descriptors.  My initial use case was an Amazon AWS Glacier tool I was using to upload large files that did not give me a progress bar.  I initially thought I might just modify that open source tool to give me progress, but found that it would involve substantial changes.  I should be able to find information about where any process is with regard to its file descriptors... hmm...

![fdmon screenshot](https://github.com/jephthai/fdmon/docs/fdmon.png)

So I created 'fdmon'.  You can see that the last file descriptor listed above shows me the progress of my upload.  By reading information from /proc, I am able to assemble information about which file descriptors are likely to have a useful position, and print out a display showing status over time.  

Requirements
============

All you need to have is Ruby and an operating system with a standard /proc filesystem.  Simply run the program with one argument -- the process ID (PID) that you want to monitor.  As long as you have permission for the indicated process.