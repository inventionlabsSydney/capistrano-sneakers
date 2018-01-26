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
      switch_user(role) do
        if test("[ -d #{current_path} ]")
          each_process_with_index(true) do |pid_file, idx|
            if pid_file_exists?(pid_file) && process_exists?(pid_file)
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
      switch_user(role) do
        if test("[ -d #{current_path} ]")
          each_process_with_index(true) do |pid_file, idx|
            if pid_file_exists?(pid_file) && process_exists?(pid_file)
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
      switch_user(role) do
        each_process_with_index do |pid_file, idx|
          unless pid_file_exists?(pid_file) && process_exists?(pid_file)
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
      switch_user(role) do
        each_process_with_index(true) do |pid_file, idx|
          if pid_file_exists?(pid_file) && process_exists?(pid_file)
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
      switch_user(role) do
        each_process_with_index do |pid_file, idx|
          unless process_exists?(pid_file)
            if pid_file_exists?(pid_file)
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
      switch_user(role) do
        each_process_with_index do |pid_file, idx|
          unless pid_file_exists?(pid_file)
            start_sneakers(pid_file, idx)
          end
        end
      end
    end
  end

  def each_process_with_index(reverse = false, &block)
    _pid_files = pid_files
    _pid_files.reverse! if reverse
    _pid_files.each_with_index do |pid_file, idx|
      within release_path do
        yield(pid_file, idx)
      end
    end
  end

  def pid_files
    sneakers_roles = Array(fetch(:sneakers_roles))
    sneakers_roles.select! { |role| host.roles.include?(role) }
    sneakers_roles.flat_map do |role|
      processes = fetch(:sneakers_processes)
      if processes == 1
        fetch(:sneakers_pid)
      else
        Array.new(processes) { |idx| fetch(:sneakers_pid).gsub(/\.pid$/, "-#{idx}.pid") }
      end
    end
  end

  def pid_file_exists?(pid_file)
    test(*("[ -f #{pid_file} ]").split(' '))
  end

  def process_exists?(pid_file)
    test(*("kill -0 $( cat #{pid_file} )").split(' '))
  end

  def quiet_sneakers(pid_file)
    if fetch(:sneakers_use_signals) || fetch(:sneakers_run_config)
      execute :kill, "-USR1 `cat #{pid_file}`"
    else
      begin
        execute :bundle, :exec, :sneakersctl, 'quiet', "#{pid_file}"
      rescue SSHKit::Command::Failed
        # If gems are not installed eq(first deploy) and sneakers_default_hooks as active
        warn 'sneakersctl not found (ignore if this is the first deploy)'
      end
    end
  end

  def stop_sneakers(pid_file)
    if fetch(:sneakers_run_config) == true
      execute :kill, "-SIGTERM `cat #{pid_file}`"
    else
      if fetch(:stop_sneakers_in_background, fetch(:sneakers_run_in_background))
        if fetch(:sneakers_use_signals)
          background :kill, "-TERM `cat #{pid_file}`"
        else
          background :bundle, :exec, :sneakersctl, 'stop', "#{pid_file}", fetch(:sneakers_timeout)
        end
      else
        execute :bundle, :exec, :sneakersctl, 'stop', "#{pid_file}", fetch(:sneakers_timeout)
      end
    end
  end

  def start_sneakers(pid_file, idx = 0)
    if fetch(:sneakers_run_config) == true
      # Use sneakers configuration prebuilt in
      raise "[ set :workers, ['worker1', 'workerN'] ] not configured properly, please configure the workers you wish to use" if fetch(:sneakers_workers).nil? or fetch(:sneakers_workers) == false or !fetch(:sneakers_workers).kind_of? Array

      workers = fetch(:sneakers_workers).compact.join(',')

      info "Starting the sneakers processes"

      with rails_env: fetch(:sneakers_env), workers: workers do
        rake 'sneakers:run'
      end
    end
  end

  def switch_user(role, &block)
    user = sneakers_user(role)
    if user == role.user
      block.call
    else
      as user do
        block.call
      end
    end
  end

  def sneakers_user(role)
    properties = role.properties
    properties.fetch(:sneakers_user) || fetch(:sneakers_user) || properties.fetch(:run_as) || role.user
  end
end
