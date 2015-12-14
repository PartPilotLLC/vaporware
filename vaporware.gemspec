Gem::Specification.new do |s|
  s.name        = 'vaporware'
  s.version     = '0.0.6'
  s.date        = '2015-12-13'
  s.summary     = "Vaporware"
  s.description = "A thin wrapper for running CloudFormation templates"
  s.authors     = ["Audrey Schwarz"]
  s.email       = 'acbschwarz@gmail.com'
  s.files       = ["lib/vaporware.rb"]
  s.homepage    = 'https://github.com/audreyschwarz/vaporware'
  s.license     = 'MIT'
  s.required_ruby_version = '~> 2'
  s.add_runtime_dependency 'aws-sdk', '~> 2'
  s.add_development_dependency 'pry', '~> 0.10'
  s.add_development_dependency 'minitest', '~> 5.8'
end
