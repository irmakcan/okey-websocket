module Okey

  class Clock
    def self.time
      Time.now.to_i
    end
  end

  module Timer

    attr_accessor :start_time, :stop_time, :last_lap, :total_time, :max_time
    def total_time
      @total_time ||= 0
    end

    def current_time
      unless @start_time.nil?
        Clock.time - @start_time + total_time
      else
        total_time
      end
    end

    def start_timer!
      @start_time = Clock.time
    end

    def stop_timer!
      @stop_time = Clock.time
      @last_lap  = @stop_time - @start_time
      @start_time = nil
      total_time
      @total_time += @last_lap
    end

    def reset_time
      @start_time = nil
      @stop_time = nil
      @last_lap = nil
      @total_time = 0
    end

    def time_left?
      @max_time.nil? || current_time <= @max_time
    end

  end
end