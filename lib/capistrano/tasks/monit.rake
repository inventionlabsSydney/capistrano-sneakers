namespace :load do
  task :defaults do
    set :monit_bin, '/usr/bin/monit'
    set :sneakers_monit_default_hooks, true
    set :sneakers_monit_conf_dir, -> { '/etc/monit/conf.d' }
    set :sneakers_monit_use_sudo, true
    set :sneakers_monit_templates_path, 'config/deploy/templates'
  end
end

namespace :deploy do
  before :starting, :check_sidekiq_monit_hooks do
    if fetch(:sneakers_default_hooks) && fetch(:sneakers_monit_default_hooks)
      invoke 'sneakers:monit:add_default_hooks'
    end
  end
end

namespace :sneakers do
  namespace :monit do
    task :add_default_hooks do
      before 'deploy:updating', 'sneakers:monit:unmonitor'
      after 'deploy:published', 'sneakers:monit:monitor'
    end

    desc 'Config Sneakers monit-service'
    task :config do
      on roles(fetch(:sneakers_roles)) do |role|
        @role = role
        upload_sneakers_template 'sneakers_monit', "#{fetch(:tmp_dir)}/monit.conf", @role

        mv_command = "mv #{fetch(:tmp_dir)}/monit.conf #{fetch(:sneakers_monit_conf_dir)}/#{sneakers_service_name}.conf"
        sudo_if_needed mv_command

        sudo_if_needed "#{fetch(:monit_bin)} reload"
      end
    end

    desc 'Monitor Sneakers monit-service'
    task :monitor do
      on roles(fetch(:sneakers_roles)) do
        sudo_if_needed "#{fetch(:monit_bin)} monitor #{sneakers_service_name}"
      end
    end

    desc 'Unmonitor Sneakers monit-service'
    task :unmonitor do
      on roles(fetch(:sneakers_roles)) do
        sudo_if_needed "#{fetch(:monit_bin)} unmonitor #{sneakers_service_name}"
      end
    end

    desc 'Start Sneakers monit-service'
    task :start do
      on roles(fetch(:sneakers_roles)) do
        sudo_if_needed "#{fetch(:monit_bin)} start #{sneakers_service_name}"
      end
    end

    desc 'Stop Sneakers monit-service'
    task :stop do
      on roles(fetch(:sneakers_roles)) do
        sudo_if_needed "#{fetch(:monit_bin)} stop #{sneakers_service_name}"
      end
    end

    desc 'Restart Sneakers monit-service'
    task :restart do
      on roles(fetch(:sneakers_roles)) do
        sudo_if_needed "#{fetch(:monit_bin)} restart #{sneakers_service_name}"
      end
    end

    def sneakers_service_name
      fetch(:sneakers_service_name, "sneakers_#{fetch(:application)}_#{fetch(:sneakers_env)}")
    end

    def sudo_if_needed(command)
      fetch(:sneakers_monit_use_sudo) ? sudo(command) : execute(command)
    end

    def upload_sneakers_template(from, to, role)
      template = sneakers_template(from, role)
      upload!(StringIO.new(ERB.new(template).result(binding)), to)
    end

    def sneakers_template(name, role)
      local_template_directory = fetch(:sneakers_monit_templates_path)

      search_paths = [
        "#{name}-#{role.hostname}-#{fetch(:stage)}.erb",
        "#{name}-#{role.hostname}.erb",
        "#{name}-#{fetch(:stage)}.erb",
        "#{name}.erb"
      ].map { |filename| File.join(local_template_directory, filename) }

      global_search_path = File.expand_path(
        File.join(*%w[.. .. .. generators capistrano sneakers monit templates], "#{name}.conf.erb"),
        __FILE__
      )

      search_paths << global_search_path

      template_path = search_paths.detect { |path| File.file?(path) }
      File.read(template_path)
    end
  end
end
