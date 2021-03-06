Gem::Specification.new do |s|
  s.name        = 'vaporware'
  s.version     = '0.0.8'
  s.date        = '2015-12-13'
  s.summary     = "Vaporware"
  s.description = "A thin wrapper for running CloudFormation templates"
  s.authors     = ["Audrey Schwarz"]
  s.email       = 'acbschwarz@gmail.com'
  s.files       = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.homepage    = 'https://github.com/audreyschwarz/vaporware'
  s.license     = 'MIT'
  s.required_ruby_version = '~> 2'
  s.add_dependency 'aws-sdk', '~> 2'
  s.add_development_dependency 'pry', '~> 0.10'
  s.add_development_dependency 'minitest', '~> 5.8'
end
