# frozen_string_literal: true

require 'bundler/setup'
require 'discordrb'

require_relative './tracker'
require_relative './guide'
require_relative './admin'

module PostMonitor
  class Bot
    def initialize(token)
      @trackers = {}
      @tracker_count = Hash.new { |h, k| h[k] = 0 }

      @bot = Discordrb::Bot.new(token: token)

      @bot.ready do
        @bot.game = "@#{@bot.profile.distinct}"
        listup_monitors
      end

      @bot.channel_create({ type: 0 }) do |event|
        create_tracker(event.channel)
      end

      @bot.channel_delete({ type: 0 }) do |event|
        destroy_tracker(event.id, event.server)
      end

      @bot.channel_update({ type: 0 }) do |event|
        create_tracker(event.channel)
      end

      Guide.events(@bot)
      Admin.events(@bot)
    end

    def run(background = false)
      @bot.run(background)
    end

    private

    def listup_monitors
      return if @channels
      @channels = @bot.servers.values.map(&:channels).flatten.select(&:text?)
      @channels.each { |channel| create_tracker(channel) }
    end

    def create_tracker(channel)
      server = channel.server
      destroy_tracker(channel.id, channel.server)

      return if @tracker_count[server.id] > 5

      tracker = case channel.topic
                when %r{<https://twitter.com/(\w{1,15})>}
                  Tracker::Timeline.new($1) { |links| post_link(links, channel) }
                when %r{<https://twitter.com/hashtag/([^?/]+)>}
                  Tracker::Hashtag.new($1) { |links| post_link(links, channel) }
                when %r{<https://www.youtube.com/channel/(UC[\w-]{22})>}
                  Tracker::Channel.new($1) { |links| post_link(links, channel) }
                when %r{<https://www.nicovideo.jp/tag/([^?]+)>}
                  Tracker::NicoTag.new($1) { |links| post_link(links, channel) }
                else
                  nil
                end

      return unless tracker

      @trackers[channel.id] = tracker
      @tracker_count[server.id] += 1
    end

    def destroy_tracker(channel_id, server)
      return unless @trackers[channel_id]

      @trackers[channel_id].destroy
      @tracker_count[server.id] -= 1
    end

    def post_link(links, channel)
      links.each { |link| channel.send(link) }
    end
  end
end
