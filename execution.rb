require 'dotenv/load'
require './post_monitor'

post_monitor = PostMonitor.new(ENV['POST_MONITOR_TOKEN'])
post_monitor.run
