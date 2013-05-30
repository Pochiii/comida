require "capistrano/cli"
require "bundler/capistrano"
#require "delayed/recipes"
require "yaml"

set :deploy_vars,                     YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), "deploy.yml"))

default_run_options[:pty]             = true
default_environment["PATH"]           = '$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH'
default_environment["RBENV_ROOT"]     = '$HOME/.rbenv'
default_environment["RAILS_ENV"]      = 'production'
default_environment["RBENV_VERSION"]  = deploy_vars["ruby"]["version"]

set :application,                     deploy_vars["app"]["name"]
set :user,                            deploy_vars["app"]["user"]
set :runner,                          deploy_vars["app"]["user"]
set :use_sudo,                        true
set :ssh_options,                     { :forward_agent => true, :paranoid => true }
set :domain,                          deploy_vars["app"]["address"]
set :repository_cache,                "#{application}_cache"
set :environment,                     default_environment["RAILS_ENV"]
set :stage,                           default_environment["RAILS_ENV"]
set :rails_env,                       default_environment["RAILS_ENV"]
set :rbenv_ruby_version,              default_environment["RBENV_VERSION"]
set :ruby_version,                    default_environment["RBENV_VERSION"]
set :delayed_job_server_role,         :delayed_job
                                      
set :scm,                             :git
set :repository,                      deploy_vars["github"]["repository"]
set :branch,                          deploy_vars["github"]["branch"]
set :keep_releases,                   5
set :deploy_to,                       "/home/#{user}/#{domain}"
set :deploy_via,                      :remote_cache
set :repository_cache,                "#{application}_cache"
set :git_enable_submodules,           true

role :web,                            domain
role :app,                            domain
role :db,                             domain, :primary => true
role :delayed_job,                    domain


def shell_for(cmd, user, machine)
  login = %(#{user}@#{machine})
  args = ['ssh', login, '-t', cmd]
  system(*args) 
end


namespace :nginx do

  desc "Create a configuration file"
  task :setup, :roles => :web, :except => { :no_release => true } do
    nginx_config = ""
    run "mkdir -p #{shared_path}/config"
    put nginx_config, "#{shared_path}/config/nginx.conf"
    sudo "ln -nfs #{shared_path}/config/nginx.conf /etc/nginx/sites-available/#{application}.conf"
    sudo "ln -nfs /etc/nginx/sites-available/#{application}.conf /etc/nginx/sites-enabled/#{application}.conf"
  end

  desc "Start nginx"
  task :start, :roles => :web do
    sudo "/usr/sbin/service nginx start"
  end

  desc "Restart nginx"
  task :restart, :roles => :web do
    sudo "/usr/sbin/service nginx restart"
  end

  desc "Reload nginx"
  task :reload, :roles => :web do
    sudo "/usr/sbin/service nginx reload"
  end

  desc "Stop nginx"
  task :reload, :roles => :web do
    sudo "/usr/sbin/service nginx stop"
  end

end


namespace :postgresql do
  
  desc "Start postgresql"
  task :start, :roles => :db do
    sudo "/usr/sbin/service postgresql start"
  end
  
  desc "Reload postgresql"
  task :reload, :roles => :db do
    sudo "/usr/sbin/service postgresql reload"
  end
  
  desc "Restart postgresql"
  task :restart, :roles => :db do
    sudo "/usr/sbin/service postgresql restart"
  end
  
  desc "Stop postgresql"
  task :stop, :roles => :db do
    sudo "/usr/sbin/service postgresql stop"
  end
  
  desc "Run postgresql client"
  task :client, :roles => :db do
    shell_for "sudo su - postgres -c 'psql -U postgres'", user, domain
  end
  
end


namespace :mongodb do
  
  desc "Start mongodb"
  task :start, :roles => :db do
    sudo "/usr/sbin/service mongodb start"
  end
  
  desc "Reload mongodb"
  task :reload, :roles => :db do
    sudo "/usr/sbin/service mongodb reload"
  end
  
  desc "Restart mongodb"
  task :restart, :roles => :db do
    sudo "/usr/sbin/service mongodb restart"
  end
  
  desc "Stop mongodb"
  task :stop, :roles => :db do
    sudo "/usr/sbin/service mongodb stop"
  end
  
  desc "Mongodb status"
  task :ping, :roles => :db do
    sudo "/usr/sbin/service mongodb status"
  end
  
end


namespace :redis do

  desc "Start redis"
  task :start, :roles => :db , :except => { :no_release => true } do
    sudo "/usr/sbin/service redis-server start"
  end
  
  desc "Restart redis"
  task :restart, :roles => :db , :except => { :no_release => true } do
    sudo "/usr/sbin/service redis-server restart"
  end
  
  desc "Stop redis"
  task :stop, :roles => :db , :except => { :no_release => true } do
    sudo "/usr/sbin/service redis-server stop"
  end
  
  desc "Ping redis"
  task :ping, :roles => :db , :except => { :no_release => true } do
    run "redis-cli ping"
  end

end


namespace :monit do

  desc "Start monit"
  task :start, :roles => [:app, :db, :web] do
    sudo "/usr/sbin/service monit start"
  end
  
  desc "Restart monit"
  task :restart, :roles => [:app, :db, :web] do
    sudo "/usr/sbin/service monit restart"
  end
  
  desc "Stop monit"
  task :stop, :roles => [:app, :db, :web] do
    sudo "/usr/sbin/service monit stop"
  end

  desc "Monit status"
  task :status, :roles => [:app, :db, :web] do
    sudo "/usr/sbin/service monit status"
  end

end


namespace :deploy do

  desc "Generate peppers"
  task :generate_peppers, :roles => [:app, :db, :web] do
    run "cd #{current_path} && if [ ! -f config/security_token ]; then bundle exec rake secret > config/security_token; fi"
    run "cd #{current_path} && if [ ! -f config/devise_pepper ];  then bundle exec rake secret > config/devise_pepper; fi"
  end

  desc "Setup database"
  task :setupdb do
    run "cd #{current_path} && bundle exec rake db:create"
  end

  desc "Get a console"
  task :console, :roles => :app do
    shell_for "cd #{current_path} && rails console", user, app
  end
  
  desc "Get a database console"
  task :dbconsole, :roles => :app do
    shell_for "cd #{current_path} && rails dbconsole", user, app
  end

end


namespace :log do

  desc "Read the latest entries of the logfile"
  task :read, :roles => [:app, :web] do
    stream "tail #{shared_path}/log/#{stage}.log"
  end

  desc "Keep reading the latest entries of the logfile"
  task :tail, :roles => [:app, :web] do
    stream "tail -f #{shared_path}/log/#{stage}.log"
  end

end

after "deploy:create_symlink", "deploy:generate_peppers"

#namespace :deploy do
#  namespace :db do
#    desc "Create a database.yml configuration file"
#    task :create_yaml, :roles => :web , :except => { :no_release => true } do
#      db_config = <<-EOF
#production:
#  adapter: postgresql
#  encoding: unicode
#  database: #{application}_prod
#  pool: 100
#  username: rodrigo
#  password: rodrigo
#  host: localhost
#  port: 5432
#  schema_search_path: public
#  min_messages: error
#development:
#  adapter: postgresql
#  encoding: unicode
#  database: #{application}_dev
#  pool: 5
#  username: rodrigo
#  password: rodrigo
#  host: localhost
#  port: 5432
#  schema_search_path: public
#  min_messages: notice
#test:
#  adapter: postgresql
#  encoding: unicode
#  database: #{application}_test
#  pool: 5
#  username: rodrigo
#  password: rodrigo
#  host: localhost
#  port: 5432
#  schema_search_path: public
#  min_messages: warning
#EOF
#      run "mkdir -p #{shared_path}/config"
#      put db_config, "#{shared_path}/config/database.yml"
#    end
#    desc "Create Production Database"
#    task :create do
#      run "cd #{current_path} && bundle exec rake db:create"
#      system "cap deploy:set_permissions"
#    end
#    desc "Migrate Production Database"
#    task :migrate do
#      run "cd #{current_path} && bundle exec rake db:migrate"
#      system "cap deploy:set_permissions"
#    end
#    desc "Resets the Production Database"
#    task :migrate_reset do
#      run "cd #{current_path} && bundle exec rake db:migrate:reset"
#    end
#    desc "Destroys Production Database"
#    task :drop do
#      run "cd #{current_path} && rake db:drop"
#      system "cap deploy:set_permissions"
#    end
#    desc "Populates the Production Database"
#    task :seed do
#      run "cd #{current_path} && bundle exec rake db:seed"
#    end
#  end
#  desc "Symlink shared configs and folders on each release."
#  task :symlink_shared do
#    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
#    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
#  end
#end
#
#after "deploy:create_symlink", "deploy:symlink_shared"
#after "deploy:symlink_shared", "deploy:generate_peppers"
#after "deploy:generate_peppers", "deploy:db:create"
#after "deploy:db:create", "deploy:db:migrate"
#after "deploy:db:migrate", "deploy:cleanup"
#after "deploy:cleanup", "delayed_job:restart"
#after "deploy:stop", "delayed_job:stop"
#after "deploy:start", "delayed_job:start"