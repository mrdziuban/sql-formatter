require 'net/http'
require 'opal/rspec/rake_task'

Opal::RSpec::RakeTask.new(:default) do |server, task|
  task.runner = :node
  task.default_path = File.expand_path(File.join('..', 'tests', 'opal'), __FILE__)
  task.pattern = File.join('tests', 'opal', '**', '*_spec.rb')

  server.append_path File.expand_path(File.join('..', 'opal', 'src'), __FILE__)
end
