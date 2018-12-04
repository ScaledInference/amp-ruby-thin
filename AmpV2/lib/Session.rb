
require 'date'
require 'net/https'
require 'json'
require 'securerandom'

class Session 
	MAX_CANDIDATES = 50

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

	def getAmpAgent()
		x = @userid.hash % @domain.length
		if (x < 0) 
			x += @domain.length
		end
		@domain[x] 
	end

	def getEndpoint(name:)
		chosen_domain = getAmpAgent()
        uri = URI(chosen_domain + @apiPath + @project_key + name)
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

	def observe(event:, props:, options:)
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
			"name": event,
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

    def checkCandidates(candidates:)
        num_candidates = 1
        candidates.each do |key, value|
            num_candidates *= value.length
        end
        if num_candidates > MAX_CANDIDATES
            raise "Too many candidates"
        end
    end

    def decide(decision:, candidates:, options:)
    	ts = DateTime.now
	    @updated = ts
	    options['timeout'] = options['timeout'] || @timeout
	    options['limit'] = options['limit'] || 1;

	    uri = getEndpoint(name: '/decideV2')

	    if decision == nil || decision == ''
	        raise "Decision name cannot be empty"
	    end

	    checkCandidates(candidates: candidates)

	    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        req.body = {
		"userId": @userId, 
		"sessionId": @id, 
		"name": decision, 
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

    def decideWithContext(context: , properties:, decision:, candidates:, options:) 
    	ts = DateTime.now
	    @updated = ts
	    options['timeout'] = options['timeout'] || @timeout
	    options['limit'] = options['limit'] || 1;

	    if decision == nil || decision == ''
	        raise "Decision name cannot be empty"
	    end

	    checkCandidates(candidates: candidates)

	    uri = getEndpoint(name: '/decideWithContextV2')

	    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        req.body = {
		"userId":@userId,
		"sessionId":@id, 
		"name": context,
		"properties": properties,
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