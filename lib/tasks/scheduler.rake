desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'
  require 'date'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  url = "https://www.sanspo.com/rss/baseball/news/baseball-n.xml"

  xml = open(url).read.toutf8
  doc = REXML::Document.new(xml)

  title = doc.elements["rss/channel/item[1]/title"].text
  link = doc.elements["rss/channel/item[1]/link"].text

  if Date.today.strftime("%A") == "Monday"
    word = "月曜は野球ないから寂しいなあ,"
  end

  push ="#{word}最新の野球ニュースが届いてるで~\n#{title}\n#{link}"
  user_ids = User.all.pluck(:line_id)
  message = {
    type: 'text',
    text: push
  }
  response = client.multicast(user_ids, message)
  "OK"
end
