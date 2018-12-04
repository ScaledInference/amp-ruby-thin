require 'Session'

class Amp
    def initialize(config)
        if config['key'] == nil || config['domain'] == nil
            raise "project key and domain are required"
        end
    	@apiPath = config['apiPath'] || 'api/core/v2/'
	    @domain = config['domain']
	    @options = config
	    @timeout = config['timeout'] || 10 * 1000
        @sessionLifetime = config['sessionLifetime'] || 30 * 60 * 1000
	    @version = '1.0.0'
	    @project_key = config['key'] 
        @dont_use_token = config['dont_use_token']
        checkAmpAgent()
    end

    class << self
    	attr_accessor :domain
    	attr_accessor :apiPath
  	end


    def checkAmpAgent()
        @domain.map! { |d|
            if not d.end_with?("/")
                d = d + "/"
            end
        }

        @domain.each { |d|
            if not d.start_with?("http")
                raise "Amp agent domains must start with http(s)"
            end

            uri = URI(d + 'test/update_from_spa/' + @project_key)
            req = Net::HTTP::Get.new(uri.path, initheader = {'Content-Type' =>'application/json'})
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == "https")
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            res = http.request(req)
            case res
            when Net::HTTPSuccess, Net::HTTPRedirection
              # OK
              puts d  + " tested OK"
            else
              raise "Invalid Amp agent domain"
            end
        }
    end

    def Session(options = {})
    	options['amp'] = self
        if @dont_use_token 
            options['ampToken'] = "CUSTOM"
        end

        if options['timeout'] == nil
            options['timeout'] = @timeout
        end

        if options['sessionLifetime'] == nil
            options['sessionLifetime'] = @sessionLifetime
        end

    	return Session.new(@domain, @apiPath, @project_key, options)
    end
end





