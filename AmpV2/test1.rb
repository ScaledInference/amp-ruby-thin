require 'Amp'

amp = Amp.new({'key' => 'da269c0cda33b03f', 'domain' => 'http://localhost:8100'})


#100.times do
   # do work here
    session1 = amp.Session()
    oldAmpToken = session1.observe(name:'UserType', props: {
    		"key1":"value1",
    		"key2":2, 
    		"key3":3.0, 
    		"key4": false}, options: {}, cb: '')
    print oldAmpToken


    session2 = amp.Session(options: { ampToken: oldAmpToken})
    
    print '\n\n'
    print session2.decide(
        name:'DecisionPoint1', 
        candidates: {   
            color: ['red', 'green'],
            number: [3,2,1]
        }, 
        options: {limit: 2, timeout: 0}, cb: '')
    print "\n\n"

    print session2.observe(name:'Outcome', props: {
            "Metric":"1"}, options: {}, cb: '')
#end 