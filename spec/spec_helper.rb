require File.dirname(__FILE__) + '/../lib/okey'
Okey.env = :test

require 'json'
require 'pp'
require 'em-http'
require 'em-spec/rspec'

class MockWebSocketConnection < EventMachine::WebSocket::Connection
  attr_accessor :onmessage
  def initialize
    super :debug => true 
  end
end

class FakeDeferrable
  def callback(&block)
    @block = block
  end
  def succeed
    @block.call
  end
end

class FakeSocketClient < EventMachine::Connection
  attr_writer :onopen, :onclose, :onmessage
  attr_reader :data
  def initialize
    @state = :new
    @data = []
  end

  def post_init
    send_data("Rossta\r\n")
  end

  def receive_data(data)
    log "RECEIVE DATA #{data}"
    @data << data
    if @state == :new
      call_onopen
    else
      @onmessage.call(data) if @onmessage
    end
  end

  def call_onopen
    @onopen.call if @onopen
    @state = :open
  end

  def unbind
    @onclose.call if @onclose
  end
end
class FakeWebSocketClient < EM::Connection
  attr_accessor :sent_data
  attr_reader :handshake_response, :packets, :state
  
  def onopen(&blk);     @onopen = blk;    end
  def onclose(&blk);    @onclose = blk;   end
  def onerror(&blk);    @onerror = blk;   end
  def onmessage(&blk);  @onmessage = blk; end

  def get_onclose();    @onclose;   end
  def get_onerror();    @onerror;   end
  def get_onmessage();  @onmessage; end

  def initialize
    @state = :new
    @packets = []
  end

  def send(data)
    @sent_data = data
  end

end
