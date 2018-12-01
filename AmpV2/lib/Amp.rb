require 'Session'

class Amp
    def initialize(config)
        if config['key'] == nil || config['domain'] == nil
            raise "project key and domain are required"
        end
    	@apiPath = config['apiPath'] || '/api/core/v2/'
	    @domain = config['domain']
	    @options = config
	    @timeout = config['timeout']
	    @version = '1.0.0'
	    @project_key = config['key'] 
    end

    class << self
    	attr_accessor :domain
    	attr_accessor :apiPath
  	end

    def Session(options = {})
    	options['amp'] = self
    	return Session.new(@domain, @apiPath, @project_key, options)
    end
end





