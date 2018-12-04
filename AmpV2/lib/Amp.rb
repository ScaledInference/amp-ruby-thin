require 'Session'

class Amp
    def initialize(config)
        if config['key'] == nil || config['domain'] == nil
            raise "project key and domain are required"
        end
    	@apiPath = config['apiPath'] || '/api/core/v2/'
	    @domain = config['domain']
	    @options = config
	    @timeout = config['timeout'] || 10 * 1000
        @sessionLifetime = config['sessionLifetime'] || 30 * 60 * 1000
	    @version = '1.0.0'
	    @project_key = config['key'] 
        @dont_use_token = config['dont_use_token']
    end

    class << self
    	attr_accessor :domain
    	attr_accessor :apiPath
  	end

    def Session(options = {})
    	options['amp'] = self
        if @dont_use_token 
            options['ampToken'] = "CUSTOM"
        end
    	return Session.new(@domain, @apiPath, @project_key, options)
    end
end





