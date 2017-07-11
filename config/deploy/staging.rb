set :application, 'staging-svt'
set :deploy_to, "/var/www/#{fetch(:application)}"
