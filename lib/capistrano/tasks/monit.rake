namespace :load do
  task :defaults do
    set :sneakers_monit_conf_dir, -> { "/etc/monit/conf.d/#{sneakers_monit_service_name}.conf" }
    set :sneakers_monit_use_sudo, true
    set :sneakers_monit_bin, '/usr/bin/monit'
  end
end

namespace :sneakers do
  namespace :monit do
    desc 'Add Sneakers to monit'
    task :config do
      on roles(fetch(:sneakers_role)) do |role|
        @role = role
        template_sneakers 'sneakers_monit.conf', "#{fetch(:tmp_dir)}/monit.conf", @role
        sudo_if_needed "mv #{fetch(:tmp_dir)}/monit.conf #{fetch(:sneakers_monit_conf_dir)}"
        sudo_if_needed "#{fetch(:sneakers_monit_bin)} reload"
      end
    end

    desc 'Enable Sneakers monit'
    task :monitor do
      on roles(fetch(:sneakers_role)) do
        sudo_if_needed "#{fetch(:sneakers_monit_bin)} monitor #{sneakers_monit_service_name}"
      end
    end

    desc 'Disable Sneakers monit'
    task :unmonitor do
      on roles(fetch(:sneakers_role)) do
        sudo_if_needed "#{fetch(:sneakers_monit_bin)} unmonitor #{sneakers_monit_service_name}"
      end
    end

    desc 'Start Sneakers through monit'
    task :start do
      on roles(fetch(:sneakers_role)) do
        sudo_if_needed "#{fetch(:sneakers_monit_bin)} start #{sneakers_monit_service_name}"
      end
    end

    desc 'Stop Sneakers through monit'
    task :stop do
      on roles(fetch(:sneakers_role)) do
        sudo_if_needed "#{fetch(:sneakers_monit_bin)}  stop #{sneakers_monit_service_name}"
      end
    end

    desc 'Restart Sneakers through monit'
    task :restart do
      on roles(fetch(:sneakers_role)) do
        sudo_if_needed "#{fetch(:sneakers_monit_bin)} restart #{sneakers_monit_service_name}"
      end
    end

    before 'deploy:updating', 'sneakers:monit:unmonitor'
    after 'deploy:published', 'sneakers:monit:monitor'

    def sneakers_monit_service_name
      fetch(:sneakers_monit_service_name, "sneakers_#{fetch(:application)}_#{fetch(:stage)}")
    end

    def sudo_if_needed(command)
      fetch(:sneakers_monit_use_sudo) ? sudo(command) : execute(command)
    end

    def template_sneakers(from, to, role)
      [
        File.join('lib', 'capistrano', 'templates', "#{from}-#{role.hostname}-#{fetch(:stage)}.rb"),
        File.join('lib', 'capistrano', 'templates', "#{from}-#{role.hostname}.rb"),
        File.join('lib', 'capistrano', 'templates', "#{from}-#{fetch(:stage)}.rb"),
        File.join('lib', 'capistrano', 'templates', "#{from}.rb.erb"),
        File.join('lib', 'capistrano', 'templates', "#{from}.rb"),
        File.join('lib', 'capistrano', 'templates', "#{from}.erb"),
        File.expand_path("../../templates/#{from}.rb.erb", __FILE__),
        File.expand_path("../../templates/#{from}.erb", __FILE__)
      ].each do |path|
        if File.file?(path)
          erb = File.read(path)
          upload! StringIO.new(ERB.new(erb).result(binding)), to
          break
        end
      end
    end
  end
end
