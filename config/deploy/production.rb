set :application, 'svt'
set :deploy_to, "/var/www/#{fetch(:application)}"
set :branch, 'master'
