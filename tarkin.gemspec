Gem::Specification.new do |s|
  s.name          = 'tarkin'
  s.version       = '0.9.2.0'
  s.date          = '2015-06-05'
  s.summary       = "Tarkin client"
  s.description   = "Tarkin Team Password Manager client and command line"
  s.authors       = ["Tomek Gryszkiewicz"]
  s.email         = "grych@tg.pl"
  s.files         = ["lib/tarkin.rb"]
  s.homepage      = "https://github.com/grych/tarkin-client"
  s.license       = "MIT"
  s.add_runtime_dependency "highline", ">= 1.7.2"
  s.add_runtime_dependency "arest", ">= 0.9.1.1"
  # s.add_runtime_dependency "colorize", ">= 0.7.7"
  s.add_runtime_dependency "command_line_reporter", ">= 3.3.5"
  s.add_development_dependency "rspec", '~> 3.2', '>= 3.2.0'
  s.add_development_dependency "bundler", "~> 1.8"
end
