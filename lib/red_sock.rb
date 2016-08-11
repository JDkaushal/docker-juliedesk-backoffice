require 'websocket-client-simple'
require 'json'

module RedSock

  def self.url= url
    @@url = url
  end

  def self.url
    @@url
  end
  def self.trigger channel_name, event_name, data={}
    WebSocket::Client::Simple.connect @@url do |ws|
      ws.on :open do
        ws.send({channel: channel_name,  action: "message", message: event_name, data: data}.to_json)
        ws.close
      end
    end
  end

  def self.get_channel_info channel_name, timeout=5000

    data = nil
    WebSocket::Client::Simple.connect @@url do |ws|
        ws.on :message do |msg|
          data = JSON.parse(msg.data)
          ws.close
        end

        ws.on :open do
          puts ws.send({channel: channel_name,  action: "get_info"}.to_json)
        end
    end

    t = Time.now
    while data == nil
      if Time.now > t + timeout / 1000.0
        raise "Timeout"
      else
        sleep 0.1
      end
    end

    data
  end

end