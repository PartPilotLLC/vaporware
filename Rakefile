require './lib/vaporware'
require 'pry'

task :console do
  binding.pry quiet: true
end
task c: :console

task :test do
  ENV["AWS_REGION"] = "us-west-2"
  Dir["./test/*.rb"].each { |f| require f }
end
task t: :test

task default: :test
