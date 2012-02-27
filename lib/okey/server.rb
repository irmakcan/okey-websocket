module Okey
  class Server

    attr_reader :env, :host, :ws_host, :ws_port, :http_port, :version
    def self.start(opts = {})
      new(opts).start
    end

    def initialize(opts = {})
      # @room_factory = RoomFactory.new # TODO

      @env        = (opts.delete(:env) || Okey.env).to_sym
      @host       = (opts.delete(:host) || '0.0.0.0').to_s
      @ws_host    = (opts.delete(:ws_host) || '0.0.0.0').to_s
      @ws_port    = (opts.delete(:ws_port) || 8080).to_i
      @http_port  = (opts.delete(:http_port) || 3000).to_i

      @version    = (opts.delete(:version) || '0.0.0').to_s

      @opts = opts

      @user_controller = UserController.new(@version)
    end


    def start
      EventMachine.run do
        trap("TERM") { stop_server }
        trap("INT")  { stop_server }

        EventMachine::WebSocket.start(:host => @ws_host, :port => @ws_port, :debug => true) do |ws|

          puts 'Establishing websocket'
          ws.onopen do
            user = User.new(ws)

            puts 'client connected'
            puts 'subscribing to channel'

            @user_controller.subscribe(user)
            #room = @room_factory.get_room
            #room.join(user)
          end
        end
        WebServer.run!(:bind => @host, :port => @http_port, :ws_port => @ws_port, :environment => @env)
      end
    end

    def stop_server
      # Do other things before shutdown TODO
      EventMachine.stop
    end
    
  end
end

