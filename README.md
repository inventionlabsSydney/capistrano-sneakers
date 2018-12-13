# Capistrano::Sneakers

[Sneakers](https://github.com/jondot/sneakers) integration **only** for Capistrano 3

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-sneakers', github: 'inventionlabsSydney/capistrano-sneakers'

And then execute:

    $ bundle

## Usage

```ruby
# Capfile
require 'capistrano/sneakers'
require 'capistrano/sneakers/monit' # optional, to require monit tasks
```

Configurable options, shown here with defaults:

```ruby
:sneakers_default_hooks => true
:sneakers_pid => File.join(shared_path, 'tmp', 'pids', 'sneakers.pid') # ensure this path exists in production before deploying
:sneakers_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
:sneakers_log => File.join(shared_path, 'log', 'sneakers.log')
:sneakers_start_timeout => 5
:sneakers_roles => :app
:sneakers_processes => 1
# sneakers monit
:sneakers_monit_conf_dir => '/etc/monit/conf.d'
:sneakers_monit_use_sudo => true
:monit_bin => '/usr/bin/monit'
:sneakers_monit_templates_path => 'config/deploy/templates'
```

## Contributors
- [Karl Kloppenborg](https://github.com/inventionlabsSydney)
- [Andrew Babichev](https://github.com/Tensho)
- [NaixSpirit](https://github.com/NaixSpirit)
- [hpetru](https://github.com/hpetru)
- [jhollinger](https://github.com/jhollinger)
- [redrick](https://github.com/redrick)

## Contributing

1. Fork it (https://github.com/inventionlabsSydney/capistrano-sneakers)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
