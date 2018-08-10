module Capistrano
  module Sneakers
    module HelperMethods
      def sneakers_each_process_with_index(reverse = false, &block)
        _pid_files = sneakers_pid_files
        _pid_files.reverse! if reverse
        _pid_files.each_with_index do |pid_file, idx|
          within release_path do
            yield(pid_file, idx)
          end
        end
      end

      def sneakers_pid_files
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

      def sneakers_pid_file_exists?(pid_file)
        test(*("[ -f #{pid_file} ]").split(' '))
      end

      def sneakers_process_exists?(pid_file)
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

      def sneakers_switch_user(role, &block)
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
  end
end

