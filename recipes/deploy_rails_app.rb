#######################
# User
#######################

# Seria para usar de forma apilable, para facer o deploy de varias apps
#node["apps"]["rails"].each do |app|

# de momento solo vai a aceptar 1
app = node["apps"]["rails"]


group app["group"]

user app["user"] do
  shell "/bin/bash"
  group app["group"]
end

directory app["homedir"] do
  owner app["user"]
  group app["group"]
end


if app["source"]["repo"]["private"]
    ## apanho para convertir espacios da key ssh
    #en retornos de carro
    words = app["source"]["repo"]["priv_key"].split(" ")
    fin_key = words.pop(4).join(" ")
    
    key = words.shift(4).join(" ")
    key << "\n"
    key << words.join("\n")
    key << "\n"
    key << fin_key
    ######################################################

    directory app["homedir"]+"/.ssh" do
      owner app["user"]
      group app["group"]
      mode '0700'
    end

    file "#{app["homedir"]}/.ssh/id_rsa" do
        owner app["user"]
        group app["group"]
        mode "0600"
        content key
    end

    cookbook_file "#{app["homedir"]}/gitssh.sh" do
        source "gitssh.sh"
        owner app["user"]
        mode 00700
    end
end


#######################
# Packages
#######################

include_recipe "build-essential"

%w{
  subversion
  git-core
}.each do |pgk|
  package pgk
end

gem_package "bundler"

####################
# application
# ##################
case app['database']['type']
  when "sqlite"
    include_recipe "lang_ruby::_sqlite"
  when "mysql"
    include_recipe "lang_ruby::_mysql"
  #when "postgresql"
end

# entornos validos
ENTORNOS = %w{development test production}

deploy_revision app["domain"] do

  repository app['source']['repo']["url"]
  revision app['source']["repo"]['reference']
  deploy_to app['deploy_to']
  ssh_wrapper "#{app['homedir']}/gitssh.sh"

  user app["user"]
  group app["group"]
  environment "RAILS_ENV" => app["environment"]

  before_migrate do
    %w{config log system pids}.each do |dir|
      directory "#{app['deploy_to']}/shared/#{dir}" do
        owner app["user"]
        group app["group"]
        mode '0755'
        recursive true
      end
    end

    ## calculamos que partes do bundle que non necesitamos
    #bundle_excluir = ['development', 'test']
    bundle_excluir = []
    ENTORNOS.each do |entorno|
        bundle_excluir.push(entorno) unless entorno == app["environment"]
    end

    case app['database']['type']
      when "sqlite"
        bundle_excluir += %w{postgresql mysql}

        file "#{release_path}/db/#{app["environment"]}.db" do
          owner app["user"]
          group app["group"]
          mode "0644"
        end
      when "mysql"
          bundle_excluir << 'postgresql'
          bundle_excluir << 'sqlite'
      when "postgresql"
          bundle_excluir << "mysql"
          bundle_excluir << "sqlite"

    end

    #template "#{app['deploy_to']}/shared/config/configuration.yml" do
    #  source "configuration.yml"
    #  owner app["user"]
    #  group app["group"]
    #  mode "0664"
    #end

    template "#{app['deploy_to']}/shared/config/database.yml" do
      source "database.yml"
      owner app["user"]
      group app["group"]
      variables ({
                :database_type => app['database']['type'],
                :database_host => app['database']['hostname'],
                :database_name => app['database']['name'],
                :database_user => app['database']['username'],
                :database_password => app['database']['password']
                })
      mode "0664"
    end

    #template "#{release_path}/Gemfile.lock" do
    #  source "redmine/Gemfile.lock"
    #  owner "redmine"
    #  group "redmine"
    #  mode "0664"
    #end
    
    rvm_shell "bundle install" do    
        user        app["user"]
        group       app["group"]
        cwd         release_path
        ## fundamental meter o --path dentro do propio deploy, senon trata de instalar no home do usuario que lance o sudo
        code        %{bundle install --path=vendor/bundle --binstubs --without #{bundle_excluir.join(' ')}}
    end
    
  end

  #migrate true
  #migration_command 'bundle exec rake db:migrate:all'
  #migrate false
  #action :force_deploy
  action :deploy
end

## aplicamos as migracions da bbdd fora do deploy revision
# porque non sabemos como meter esta chamada o rvm_shell dentro da migracion
rvm_shell "rake db:migrate" do    
        user        app["user"]
        group       app["group"]
        cwd         "#{app["deploy_to"]}/current"
        code        "RAILS_ENV=#{app["environment"]} bundle exec rake db:migrate"
end

## compilamos os assets
rvm_shell "rake assets:precompile" do    
        user        app["user"]
        group       app["group"]
        cwd         "#{app["deploy_to"]}/current"
        code        "RAILS_ENV=#{app["environment"]} bundle exec rake assets:precompile"
end

## finalmente creamos un link
link app["dir"] do
  to "#{app["deploy_to"]}/current"
end

# O MELLOR E CREAR UN LWRP XENERICO QUE PERMITA CONFIGURAR VHOSTS 
# MOLARIA QUE VALERA TANTO PARA NGINX, COMO PARA APACHE
# E TANTO PARA RUBY, COMO PARA PHP, PYTHON ...
#
#
=begin

## creamos o vhost
redmine_site = {"domain" => node["redmine"]["domain"],
		        "document_root" => node["redmine"]["dir"]}

node.run_state['appserver_rails_sites'] = 
    node.run_state['appserver_rails_sites'] | [redmine_site]
end
=end

site = {"domain" => app["domain"],
		"document_root" => app["dir"]}

node.set['lang']['ruby']['rails']['sites'] = 
    node['lang']['ruby']['rails']['sites'] | [site]

include_recipe "appserver_nginx::add_passenger_site"
