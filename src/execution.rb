# frozen_string_literal: true

require 'dotenv/load'
require_relative './post_monitor/bot'

post_monitor = PostMonitor::Bot.new(ENV['POST_MONITOR_TOKEN'])
post_monitor.run
