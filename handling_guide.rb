module HandlingGuide
  private
  def set_guide_command
    @bot.mention do |event|
      next unless event.channel.text?
      next if event.content != @bot.profile.mention
      next unless event.author.permission?(:manage_channels, event.channel)

      event.send_embed do |embed|
        embed.color = 0xffa500
        embed.title = "📬 Post Monitor の使い方"
        embed.url = "https://github.com/GrapeColor/post_monitor/blob/master/README.md"

        embed.description = 
          "Twitterのハッシュタグやタイムラインを監視し、" +
          "新しい投稿をチャンネルに転送するBOTです。\n" +
          "監視したいコンテンツのURLを **チャンネルトピック** に " +
          "`<>` で囲んで指定してください。\n" +
          "各チャンネルに設定できる監視コンテンツは **１つまで** です。\n\n" +

          "✅ **対応コンテンツ一覧** (最大取得件数/取得間隔)"
        embed.add_field(
          name: "🇦 Twitterタイムライン (20件/5分)",
          value: "```<https://twitter.com/(ユーザーID)>```"
        )
        embed.add_field(
          name: "🇧 Twitterハッシュタグ (100件/10分)",
          value: "```<https://twitter.com/hashtag/(ハッシュタグ名)>```"
        )
        embed.add_field(
          name: "🇨 YouTubeチャンネル動画投稿/配信 (15件/1分)",
          value: "```<https://www.youtube.com/channel/(チャンネルID)>```"
        )
        embed.add_field(
          name: "🇩 ニコニコ動画タグ (32件/5分)",
          value: "```<https://www.nicovideo.jp/tag/(タグ名)>```"
        )
      end
    end
  end
end
