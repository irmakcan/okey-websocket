module Okey
  class Server

    attr_reader :env, :host, :ws_host, :ws_port, :http_port
    @@version = nil
    def self.start(opts = {})
      new(opts).start
    end

    def initialize(opts = {})
      # @room_factory = RoomFactory.new # TODO

      @env                = (opts.delete(:env) || Okey.env).to_sym
      @host               = (opts.delete(:host) || '0.0.0.0').to_s
      @ws_host            = (opts.delete(:ws_host) || '0.0.0.0').to_s
      @ws_port            = (opts.delete(:ws_port) || 8080).to_i
      @http_port          = (opts.delete(:http_port) || 3000).to_i
      @inactivity_timeout = (opts.delete(:inactivity_timeout) || 300).to_i

      @@version    = (opts.delete(:version) || '0.0.0').to_s

      @opts = opts
      @debug = (@env == :production ? false : true)
      @user_controller = UserController.new
    end

    def self.version
      @@version || '0.0.0'
    end

    def start
      EventMachine.run do
        trap("TERM") { stop_server }
        trap("INT")  { stop_server }

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

