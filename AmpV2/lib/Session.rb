
require 'date'
require 'net/https'
require 'json'
require 'securerandom'

class Session 

	def initialize(domain, apiPath, project_key, options = {})
		@amp = options['amp'];
	    #if (!@amp) throw new Error('Not the right way to create a session!');

	    @id = options['id'] || SecureRandom.hex(6);
	    @userId = options['userId'] || SecureRandom.hex(3)
	    @timeout = options['timeout'] || 30 * 1000
	    @ttl = options['ttl'] || 0
	    @index = 1
	    currentTime = DateTime.now
	    @created = currentTime
	    @updated = currentTime
	    @domain = domain
	    @apiPath = apiPath
	    @project_key = project_key
	    @ampToken = options['ampToken']
	end

	def getEndpoint(name:)
    	uri = URI(@domain + @apiPath + @project_key + name)
    	uri
    end

    def getHttp(uri:)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = (uri.scheme == "https")
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		http
	end

	def extractDecisionV1(res:, choices:)
		index = res['debug']['decision']['index'][0]
		tmpIndex = index
		propkeys = []
		candidate = {}
		choices.each {|key, value| propkeys << key }
		keys = propkeys.sort.reverse!
		keys.each do |key|
			candidates = choices[key]
			if candidates != nil
				l = candidates.length
				candidate[key] = candidates[tmpIndex % l]
				tmpIndex /= l
			end
		end
		candidate
	end 

	def extractDecisionV2(res:)
		{
			decision: res['decision'],
		 	ampToken: res['ampToken']
		 }
	end 

	def observe(name:, props:, options:, cb:)
	    ts = DateTime.now
	    #self.startFreshIfExpired();
	    @updated = ts
	    options['timeout'] = options['timeout'] || @timeout
	    uri = getEndpoint(name: '/observeV2')

	    # Call the url
	    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
		req.body = {
			"userId":@userId, 
			"sessionId":@id, 
			"name": "#{name}",
			"ampToken": @ampToken,
			"properties": props, 
		}.to_json

		http = getHttp(uri: uri)
		res = http.request(req)
		case res
		when Net::HTTPSuccess, Net::HTTPRedirection
		  # OK
		  JSON.parse(res.body)['ampToken']
		else
		  res.value
		end

    end

    def decide(name:, candidates:, options:, cb:) 
    	ts = DateTime.now
	    @updated = ts
	    options['timeout'] = options['timeout'] || @timeout
	    options['limit'] = options['limit'] || 1;

	    uri = getEndpoint(name: '/decideV2')

	    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        req.body = {
		"userId":@userId, 
		"sessionId":@id, 
		"name": "#{name}", 
		"decision":
			{"candidates": [candidates] }
		}.to_json

	    http = getHttp(uri: uri)
		res = http.request(req)

		case res
		when Net::HTTPSuccess, Net::HTTPRedirection
		  # OK
		  response = JSON.parse(res.body)
		  extractDecisionV2(res: response)
		else
		  res.value
		end 
    end

    def decideWithContext(context: , properties:, decision:, candidates:, options:, cb:) 
    	ts = DateTime.now
	    @updated = ts
	    options['timeout'] = options['timeout'] || @timeout
	    options['limit'] = options['limit'] || 1;

	    uri = getEndpoint(name: '/decideWithContextV2')

	    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        req.body = {
		"userId":@userId,
		"sessionId":@id, 
		"name": context,
		"properties": props,
		"decisionName": decision, 
		"decision":
			{"candidates": [candidates] }
		}.to_json

	    http = getHttp(uri: uri)
		res = http.request(req)

		case res
		when Net::HTTPSuccess, Net::HTTPRedirection
		  # OK
		  response = JSON.parse(res.body)
		  extractDecisionV2(res: response)
		else
		  res.value
		end 
    end
    
end