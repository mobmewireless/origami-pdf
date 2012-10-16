lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'version'

Gem::Specification.new do |s|
  s.name        = 'origami'
  s.version     =  Origami::VERSION
  s.platform    =  Gem::Platform::RUBY
  s.date        = '2012-10-10'
  s.summary     = "Origami PDF extended version"
  s.description = "Extended the origami-pdf library to support methods to insert signature inside a PDF"
  s.authors     = ["MobMe"]
  s.email       = ["engineering@mobme.in"]
  
  s.homepage    =
    'https://github.com/mobmewireless/origami-pdf'


  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "yard"
  s.add_development_dependency "ci_reporter"
  s.add_development_dependency "simplecov-rcov"
  s.add_development_dependency "rdiscount"
  s.add_development_dependency "pry"
  
  s.files              = `git ls-files`.split("\n") - ["Gemfile.lock", ".rvmrc"]
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths      = ["lib"]
  

end