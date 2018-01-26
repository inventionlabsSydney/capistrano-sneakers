lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/sneakers/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-sneakers"
  spec.version       = Capistrano::Sneakers::VERSION
  spec.authors       = ["Spirit"]
  spec.email         = ["neverlandxy.naix@gmail.com"]
  spec.summary       = %q{Sneakers integration only for Capistrano3}
  spec.description   = %q{Sneakers integration only for Capistrano3}
  spec.homepage      = "https://github.com/NaixSpirit/capistrano-sneakers"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'capistrano', '>= 3.9.0'
  spec.add_dependency 'sneakers'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
