require 'uri'
require 'rss'
require 'twitter'

module BaseTracker
  def destroy
    @trackers.delete(self)
  end

  private
  def create_tracker(trackers, proc)
    @trackers = trackers
    trackers[self] = -> do
      links = get_links
      proc.call(links) if links
    end
  end

  def check_proc
    ->(trackers, span) do
      adjust = 0
      loop do
        sleep(span - adjust)
        start = Time.new
        trackers.values.each(&:call)
        adjust = Time.new - start
      end
    end
  end
end

module TwitterTracker
  include BaseTracker

  def initialize(value)
    @@client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end

    @value = value

    return unless tweets = get_tweets
    @last_id = tweets[0].id if tweets[0]
  end

  private
  def get_links
    return unless (tweets = get_tweets) && tweets.any?

    @last_id = tweets[0].id
    tweets.map { |tweet| tweet.uri.to_s }.reverse
  end
end

module RSSTracker
  include BaseTracker

  def initialize(value)
    @rss_uri = generate_uri(value)

    return unless data = get_data
    @last_time = data.keys[0]
  end

  private
  def get_links
    return unless data = get_data

    new_data = data.select { |time, _| time > @last_time }
    return if new_data.empty?

    @last_time = data.keys[0]
    new_data.values.reverse
  end

  def rss_parse(uri, do_validate = true)
    RSS::Parser.parse(uri, do_validate)
  rescue
    nil
  end
end

class TimelineTracker
  include TwitterTracker

  def initialize(value, &block)
    return unless super(value)

    create_tracker(@@trackers ||= {}, block)
    @@thread ||= Thread.fork(@@trackers, 300, &check_proc)
  end

  private
  def get_tweets
    options = @last_id ? { since_id: @last_id } : {}
    @@client.user_timeline(@value, options)
  rescue
    nil
  end
end

class HashtagTracker
  include TwitterTracker

  def initialize(value, &block)
    return unless super(value)

    create_tracker(@@trackers ||= {}, block)
    @@thread ||= Thread.fork(@@trackers, 600, &check_proc)
  end

  private
  def get_tweets
    options = @last_id ? { since_id: @last_id } : {}
    data = @@client.search("##{@value} exclude:retweets", options)
  rescue
    nil
  else
    data.attrs[:statuses].map { |status| Twitter::Tweet.new(status) }
  end
end

class ChannelTracker
  include RSSTracker

  def initialize(value, &block)
    return unless super(value)

    create_tracker(@@trackers ||= {}, block)
    @@thread ||= Thread.fork(@@trackers, 60, &check_proc)
  end

  private
  def generate_uri(value)
    "https://www.youtube.com/feeds/videos.xml?channel_id=#{value}"
  end

  def get_data
    return unless rss = rss_parse(@rss_uri, false)
    rss.entries.map do |entry|
      [entry.published.content, entry.author.uri.content]
    end.to_h
  end
end

class NicoTagTracker
  include RSSTracker

  def initialize(value, &block)
    return unless super(value)

    create_tracker(@@trackers ||= {}, block)
    @@thread ||= Thread.fork(@@trackers, 300, &check_proc)
  end

  private
  def generate_uri(value)
    uri = "https://www.nicovideo.jp/tag/#{value}?sort=f&rss=2.0"
    value =~ /^[%\w\-\.\\]+$/ ? uri : URI.escape(uri)
  end

  def get_data
    return unless rss = rss_parse(@rss_uri)
    rss.channel.items.map do |item|
      [item.pubDate, item.link]
    end.to_h
  end
end
