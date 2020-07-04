# frozen_string_literal: true

module PostMonitor
  module Guide
    def self.events(bot)
      bot.mention do |event|
        next unless event.channel.text?
        next if event.content != bot.profile.mention
        next unless event.author.permission?(:manage_channels, event.channel)

        event.send_embed do |embed|
          embed.color = 0xffa500
          embed.title = "📬 Post Monitor の使い方"
          embed.url = "https://github.com/GrapeColor/post_monitor/wiki/使用方法"

          embed.description = <<~DESC
            Twitterのハッシュタグやタイムラインを監視し、
            新しい投稿をチャンネルに転送するBOTです。
            監視したいコンテンツのURLを **チャンネルトピック** に
            `<>` で囲んで指定してください。
            各チャンネルに設定できる監視コンテンツは **１つまで** です。

            ✅ **対応コンテンツ一覧** (最大取得件数/取得間隔)
          DESC

          embed.add_field(
            name: "🇦 Twitterタイムライン (20件/5分)",
            value: "```fix\n<https://twitter.com/ユーザーID>\n```"
          )
          embed.add_field(
            name: "🇧 Twitterハッシュタグ (100件/10分)",
            value: "```fix\n<https://twitter.com/hashtag/ハッシュタグ名>\n```"
          )
          embed.add_field(
            name: "🇨 YouTubeチャンネル動画投稿/配信 (15件/1分)",
            value: "```fix\n<https://www.youtube.com/channel/チャンネルID>\n```"
          )
          embed.add_field(
            name: "🇩 ニコニコ動画タグ (32件/5分)",
            value: "```fix\n<https://www.nicovideo.jp/tag/タグ名>\n```"
          )
        end
      end
    end
  end
end
