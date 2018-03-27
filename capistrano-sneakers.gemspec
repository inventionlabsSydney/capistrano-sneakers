lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/sneakers/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-sneakers"
  spec.version       = Capistrano::Sneakers::VERSION
  spec.authors       = ["Karl Kloppenborg, Andrew Babichev, NaixSpirit"]
  spec.email         = ["k@rl.ag", "andrew.babichev@gmail.com", "neverlandxy.naix@gmail.com"]
  spec.summary       = %q{Sneakers integration for Capistrano}
  spec.description   = %q{Sneakers integration for Capistrano}
  spec.homepage      = "https://github.com/inventionlabsSydney/capistrano-sneakers"
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
