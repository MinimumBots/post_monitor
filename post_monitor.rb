require 'bundler/setup'
require 'discordrb'

require_relative './trackers'
require_relative './handling_guide'
require_relative './admin_command'

class PostMonitor
  include HandlingGuide
  include AdminCommnad

  def initialize(token)
    @trackers = {}
    @tracker_count = Hash.new { |hash, key| hash[key] = 0 }

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

    set_guide_command

    set_admin_command
  end

  def run(async = false)
    @bot.run(async)
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
    @trackers[channel.id] = case channel.topic
      when %r{<https://twitter.com/(\w{1,15})>}
        TimelineTracker.new($1) { |links| post_link(links, channel) }
      when %r{<https://twitter.com/hashtag/([^?/]+)>}
        HashtagTracker.new($1) { |links| post_link(links, channel) }
      when %r{<https://www.youtube.com/channel/(UC[\w-]{22})>}
        ChannelTracker.new($1) { |links| post_link(links, channel) }
      when %r{<https://www.nicovideo.jp/tag/([^?]+)>}
        NicoTagTracker.new($1) { |links| post_link(links, channel) }
      else
        nil
      end

    @tracker_count[server.id] += 1
  end

  def destroy_tracker(channel_id, server)
    if @trackers[channel_id]
      @trackers[channel_id].destroy
      @tracker_count[server,id] -= 1
    end
  end

  def post_link(links, channel)
    links.each { |link| channel.send(link) }
  end
end
