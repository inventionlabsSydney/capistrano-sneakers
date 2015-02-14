require 'capistrano/sneakers/version'

if Gem::Specification.find_by_name('capistrano').version >= Gem::Version.new('3.0.0')
  load File.expand_path('../tasks/sidekiq.cap', __FILE__)
else
  raise Gem::LoadError, 'We are Sorry, this gem only for Capistrano3, please install Capistrano3 first.'
end
