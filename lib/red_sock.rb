require 'faye/websocket'
require 'eventmachine'
require 'json'

module RedSock

  def self.url= url
    @@url = url
  end

  def self.url
    @@url
  end

  def self.trigger channel_name, event_name, data={}
    EM.run {

      # 3 sec timeout
      EM.add_timer(3) { EM.stop }

      # Broadcast message
      ws = Faye::WebSocket::Client.new(RedSock.url)
      ws.on :open do
        ws.send({channel: channel_name,  action: "message", message: event_name, data: data}.to_json)
        ws.close
      end

      # Stop event machine when message is broadcast
      ws.on(:close) { EM.stop }
    }
  end

  def self.get_channel_info channel_name
    data = []
    EM.run {
      EM.add_timer(3) { EM.stop }

      ws = Faye::WebSocket::Client.new(RedSock.url)
      ws.on :message do |msg|
        data = JSON.parse(msg.data)
        ws.close
      end

      ws.on :open do
        puts ws.send({channel: channel_name,  action: "get_info"}.to_json)
      end

      ws.on(:close) { EM.stop }
    }

    data
  end
end