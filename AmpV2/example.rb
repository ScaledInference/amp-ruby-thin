require 'optparse'
require 'pp'
require 'Amp'

options = {}

optparse = OptionParser.new do|opts|
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end

  options[:key] = ""
  opts.on( '-k', '--key KEY', "Project Key" ) do|k|
      options[:key] = k
  end

  options[:domain] = ""
  opts.on( '-d', '--domains DOMAIN', "Amp agent domain" ) do|d|
      options[:domain] = d
  end
  opts.parse!
end

#amp = Amp.new({'key' => 'da269c0cda33b03f', 'domain' => 'http://localhost:8100'})
amp = Amp.new({'key' => options[:key], 'domain' => options[:domain]})


#100.times do
   # do work here
    session1 = amp.Session()
    oldAmpToken = session1.observe(name:'UserType', props: {
    		"key1":"value1",
    		"key2":2, 
    		"key3":3.0, 
    		"key4": false}, options: {})
    print oldAmpToken


    session2 = amp.Session(options: { ampToken: oldAmpToken})
    
    print "\n\n"

    print session2.decide(
        name:'DecisionPoint1', 
        candidates: {   
            color: ['red', 'green'],
            number: [3,2,1]
        }, 
        options: {limit: 2, timeout: 0})
    print "\n\n"

    print session2.decideWithContext(
        context: 'Custom1',
        properties: {
            'key5': 100
        },
        decision:'DecisionPoint2', 
        candidates: {   
            color: ['red', 'green', 'yellow'],
            number: [3,2,1]
        }, 
        options: {limit: 2, timeout: 0})
    print "\n\n"

    print session2.observe(name:'Outcome', props: {
            "Metric":"1"}, options: {})
#end 