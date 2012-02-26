require 'sinatra/base'

module Okey
  class WebServer < Sinatra::Base
    enable :run, :logging, :dump_errors, :raise_errors
    set :root, File.expand_path(File.dirname(__FILE__)) + "/../../"
    set :public_folder, Proc.new { File.join(root, "public") }
    set :server, %w[thin mongrel webrick]

    configure :test do
      disable :logging, :dump_errors, :raise_errors, :run
    end

    get "/page" do
      halt 401, 'go away!'
    end

    get %r{/okey|/} do
      puts "WS port: #{settings.ws_port}"
      "page"
    # erb :index
    end

  end
end