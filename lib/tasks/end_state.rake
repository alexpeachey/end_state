namespace :end_state do
  desc 'Draw the statemachine using GraphViz (options: machine=MyMachine, format=png, output=machine.png, event_labels=false)'
  task :draw do
    options = {}
    options[:machine] = ENV['machine']
    options[:format] = ENV['format'] || :png
    options[:output] = ENV['output'] || "#{options[:machine].to_s}.#{options[:format].to_s}"
    options[:event_labels] = !(ENV['event_labels'] == 'false')
    if options[:machine]
      EndState::Graph.new(Object.const_get(options[:machine])).draw.output options[:format] => options[:output]
    else
      puts 'A machine is required'
    end
  end
end
