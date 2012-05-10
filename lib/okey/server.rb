require 'em-http'

module Okey
  class Server
    UPDATE_POINTS_URL = "https://okey.herokuapp.com/okey/updatepoints"
    attr_reader :host, :ws_host, :ws_port, :http_port
    @@version, @@play_interval, @@env = "0.0.0", 30, :development
    def self.start(opts = {})
      new(opts).start
    end

    def initialize(opts = {})
      # @room_factory = RoomFactory.new # TODO

      @@env               = (opts.delete(:env) || :development).to_sym
      @host               = (opts.delete(:host) || '0.0.0.0').to_s
      @ws_host            = (opts.delete(:ws_host) || '0.0.0.0').to_s
      @ws_port            = (opts.delete(:ws_port) || 8080).to_i
      @http_port          = (opts.delete(:http_port) || 3000).to_i
      @inactivity_timeout = (opts.delete(:inactivity_timeout) || 300).to_i

      @@version           = (opts.delete(:version) || '0.0.0').to_s
      @@play_interval     = (opts.delete(:play_interval) || 20).to_i
      
      @opts = opts
      @debug = (@@env == :production ? false : true)
      @user_controller = UserController.new(:env => @@env)
    end
    
    class << self
      def env; @@env; end
      def version; @@version; end
      def play_interval; @@play_interval; end
      def update_points(user, points)
        if @@env == :production
          $redis.hset("points:#{user.username}", :points, points).callback do |result|
            EventMachine::HttpRequest.new("#{UPDATE_POINTS_URL}?username=#{user.username}").get
          end
        end
        user.points += points
      end
    end

    def start
      EventMachine.run do
        trap("TERM") { stop_server }
        trap("INT")  { stop_server }

        $redis = nil
        if @@env == :production
          $redis = EM::Hiredis.connect("redis://redistogo:b2504c1f8b7a48fe42b004a4b21cfc89@dogfish.redistogo.com:9629/")
          $redis.callback { puts "Redis now connected" }
        end

        EventMachine::WebSocket.start(:host => @ws_host, :port => @ws_port, :debug => @debug) do |ws|
          ws.onopen do
            ws.comm_inactivity_timeout=@inactivity_timeout
            user = User.new(ws)
            @user_controller.subscribe(user)
          end
        end
        
      end
    end

    def stop_server
      # Do other things before shutdown TODO
      EventMachine.stop
    end
    
  end
end

