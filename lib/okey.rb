require "bundler/setup"
require "eventmachine"
require "em-websocket"
require "json"

%w[ server user_controller user lounge room table chair messaging tiles game ].each { |file| require "okey/#{file}" }

module Okey
  class << self
    attr_accessor :env
  end
end
