require 'capistrano/sneakers/helper_methods'
include Capistrano::Sneakers::HelperMethods

namespace :load do
  task :defaults do
    set :sneakers_default_hooks, true

    set :sneakers_pid, -> { File.join(shared_path, 'tmp', 'pids', 'sneakers.pid') }
    set :sneakers_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
    set :sneakers_log, -> { File.join(shared_path, 'log', 'sneakers.log') }
    # set :sneakers_timeout, -> 10
    # TODO: Rename to plural
    set :sneakers_roles, [:app]
    set :sneakers_processes, 1
    set :sneakers_workers, false # if this is false it will cause Capistrano to exit
    # rename to sneakers_config
    set :sneakers_run_config, true # if this is true sneakers will run with preconfigured /config/initializers/sneakers.rb
    # Rbenv and RVM integration
    set :rbenv_map_bins, fetch(:rbenv_map_bins).to_a.concat(%w(sneakers))
    set :rvm_map_bins, fetch(:rvm_map_bins).to_a.concat(%w(sneakers))
  end
end

namespace :deploy do
  before :starting, :check_sneakers_hooks do
    invoke 'sneakers:add_default_hooks' if fetch(:sneakers_default_hooks)
  end

  after :publishing, :restart_sneakers do
    invoke 'sneakers:restart' if fetch(:sneakers_default_hooks)
  end
end

namespace :sneakers do
  task :add_default_hooks do
    after 'deploy:starting',  'sneakers:quiet'
    after 'deploy:updated',   'sneakers:stop'
    after 'deploy:reverted',  'sneakers:stop'
    after 'deploy:published', 'sneakers:start'
  end

  desc 'Quiet sneakers (stop processing new tasks)'
  task :quiet do
    on roles fetch(:sneakers_roles) do |role|
      sneakers_switch_user(role) do
        if test("[ -d #{current_path} ]")
          sneakers_each_process_with_index(true) do |pid_file, idx|
            if sneakers_pid_file_exists?(pid_file) && sneakers_process_exists?(pid_file)
              quiet_sneakers(pid_file)
            end
          end
        end
      end
    end
  end

  desc 'Stop sneakers'
  task :stop do
    on roles fetch(:sneakers_roles) do |role|
      sneakers_switch_user(role) do
        if test("[ -d #{current_path} ]")
          sneakers_each_process_with_index(true) do |pid_file, idx|
            if sneakers_pid_file_exists?(pid_file) && sneakers_process_exists?(pid_file)
              stop_sneakers(pid_file)
            end
          end
        end
      end
    end
  end

  desc 'Start sneakers'
  task :start do
    on roles fetch(:sneakers_roles) do |role|
      sneakers_switch_user(role) do
        sneakers_each_process_with_index do |pid_file, idx|
          unless sneakers_pid_file_exists?(pid_file) && sneakers_process_exists?(pid_file)
            start_sneakers(pid_file, idx)
          end
        end
      end
    end
  end

  desc 'Restart sneakers'
  task :restart do
    invoke! 'sneakers:stop'
    # It takes some time to stop serverengine processes and cleanup pidfiles.
    # We should wait until pidfiles will be removed.
    sleep 5
    invoke 'sneakers:start'
  end

  desc 'Rolling-restart sneakers'
  task :rolling_restart do
    on roles fetch(:sneakers_roles) do |role|
      sneakers_switch_user(role) do
        sneakers_each_process_with_index(true) do |pid_file, idx|
          if sneakers_pid_file_exists?(pid_file) && sneakers_process_exists?(pid_file)
            stop_sneakers(pid_file)
          end
          start_sneakers(pid_file, idx)
        end
      end
    end
  end

  # Delete any pid file not in use
  task :cleanup do
    on roles fetch(:sneakers_roles) do |role|
      sneakers_switch_user(role) do
        sneakers_each_process_with_index do |pid_file, idx|
          unless sneakers_process_exists?(pid_file)
            if sneakers_pid_file_exists?(pid_file)
              execute "rm #{pid_file}"
            end
          end
        end
      end
    end
  end

  # TODO : Don't start if all proccess are off, raise warning.
  desc 'Respawn missing sneakers proccesses'
  task :respawn do
    invoke 'sneakers:cleanup'
    on roles fetch(:sneakers_roles) do |role|
      sneakers_switch_user(role) do
        sneakers_each_process_with_index do |pid_file, idx|
          unless sneakers_pid_file_exists?(pid_file)
            start_sneakers(pid_file, idx)
          end
        end
      end
    end
  end
end
