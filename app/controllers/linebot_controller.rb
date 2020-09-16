class LinebotController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  protect_from_forgery :except => [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body,signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each{ |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          input = event.message['text']
          url = "https://www.sanspo.com/rss/baseball/news/baseball-n.xml"
          xml = open(url).read.toutf8
          doc = REXML::Document.new(xml)
          title = doc.elements["rss/channel/item[1]/title"].text
          link = doc.elements["rss/channel/item[1]/guid"].text
          if input.match(/.*(f最新|野球|ニュース).*/)
            word = "最新のニュースはこれやで"
          else
            word = "何を言うてんねん、ワイのできることは最新のニュースを届けるだけや"
          end
          push = "#{word}\n#{title}\n#{link}"
        else
          push = "テキストで頼むで"
        end
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'],message)
      when Line::Bot::Event::Follow
        line_id = event['source']['userId']
        User.create(line_id: line_id)
      when Line::Bot::Event::Unfollow
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new{ |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
