module Okey
  class Request
    # return parsed json or nil
    def self.parse_request(json)
      begin
        JSON.parse(json)
      rescue JSON::ParserError
        nil
      end
    end
    
  end
  
  class AuthenticationRequest
    attr_reader :parsed
    def initialize(json)
      @parsed = Request.parse_request(json)
    end
    
    def action
      @parsed['action']
    end
    
    def version
      @parsed["payload"]["version"]
    end
    
    
      
  end
end