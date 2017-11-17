# config valid only for current version of Capistrano
lock "3.10.0"

# set :application, "my_app_name"
# set :repo_url, "git@example.com:me/my_repo.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", "config/secrets.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :ssh_options, forward_agent: false, user: 'deployer'
#   keys:               %w(/home/developer/.ssh/id_rsa),

server 'dc', user: 'deployer', roles: %w[web app db]

# Repo details
set :rbenv_ruby, '2.3.1'
set :repo_url, '/var/repos/inv.git'
set :rbenv_map_bins, %w[rake gem bundle ruby rails]

set :keep_releases, 5

set :deploy_via, :remote_cache
set :use_sudo, false
set :passenger_restart_with_touch, true

set :linked_files, %w[config/database.yml config/secrets.yml .env]
set :linked_dirs, %w[log tmp/pids tmp/cache vendor/bundle public/uploads public/downloads node_modules]

SSHKit.config.command_map[:rake] = 'bundle exec rake'
SSHKit.config.command_map[:rails] = 'bundle exec rails'

namespace :deploy do
  desc 'Restart Passenger app'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end

desc 'Add default data to the database'
task :seed do
  on primary fetch(:migration_role) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, 'db:seed'
      end
    end
  end
end

desc 'Run :drop, :create and :migrate database'
task :recreate_db do
  on primary fetch(:migration_role) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, 'db:drop'
        execute :rake, 'db:create'
        execute :rake, 'db:migrate'
      end
    end
  end
end

after 'deploy', 'deploy:cleanup'
after 'deploy:publishing', 'deploy:restart'
