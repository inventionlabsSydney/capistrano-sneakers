require 'capistrano/sneakers/version'

cap_version = Gem::Specification.find_by_name('capistrano').version
if cap_version >= Gem::Version.new('3.0.0')
  #
  # Load Tasks from sneakers "cap" file
  # 
  load File.expand_path('../tasks/sneakers.cap', __FILE__)
else
  raise Gem::LoadError, "Capistrano-Sneakers requires capistrano version 3.0.0 or greater, version detected: #{cap_version}"
end
