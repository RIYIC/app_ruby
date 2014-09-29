#######################
# User
#######################

# Seria para usar de forma apilable, para poder facer o deploy de varias apps
node["app"]["ruby"]["rack_apps"].each do |app|

  #instalar paquetes de sistema necesarios
  # forzamos a que o atributo sexa tratado como un array (porque pode vir nil)
  Array(app["extra_packages"]).each do |pkg|
    package pkg
  end

  ## DE ESTO AGORA SE ENCARGA code_repo
  # # creamos o entorno da app
  # owner_home = "/home/#{app["owner"]}"

  # group app["group"]

  # user app["owner"] do
  #   shell "/bin/bash"
  #   group app["group"]
  #   home owner_home
  # end

  # directory app["target_path"] do
  #   owner app["owner"]
  #   group app["group"]
  #   recursive true
  # end

  # descargamos o codigo da app
  # en funcion do tipo de repositorio
  include_recipe "code_repo::default"

  case app["repo_type"]
  when "git" 
    provider = Chef::Provider::CodeRepoGit

  when "subversion"
    provider = Chef::Provider::CodeRepoSvn

  when "remote_archive"
    provider = Chef::Provider::CodeRepoRemoteArchive
  else
    provider = Chef::Provider::CodeRepoGit
  end

  code_repo app["target_path"] do
    provider    provider
    action      "pull"
    owner       app["owner"]
    group       app["group"]
    url         app["repo_url"]
    revision    app["revision"]
    credential  app["credential"]
    notifies    :create,"directory[#{app["target_path"]}/tmp]"
  end

  # todas as app rack deben ter un directorio tmp
  directory "#{app["target_path"]}/tmp" do
    owner app["owner"]
    group app["group"]
    action :nothing
  end

  # variables de entorno
  env_hash = {
    "RACK_ENV"  => app["environment"],
    "RAILS_ENV" => app["environment"],
    "MERB_ENV"  => app["environment"]
  }

  # instalamos a librerias que necesite a applicacion
  rvm_shell "bundle install" do    
      user        app["owner"]
      group       app["group"]
      cwd         app["target_path"]
      environment env_hash
      ## fundamental meter o --path dentro do propio deploy, senon trata de instalar no home do usuario que lance o sudo
      ## code        %{bundle install --path=vendor/bundle --binstubs --without #{app["exclude_bundler_groups"].join(' ')}}
      code        %{bundle install --deployment --binstubs --without #{app["exclude_bundler_groups"].join(' ')}}

  end

  # realizamos a migracion da bbdd e as tarefas extra de forma distinta
  # se o nodo e un container docker ou non
  if node["riyic"]["dockerized"] == "yes"

    template "/root/start.sh" do
      source "start.sh.erb"
      mode "755"
      owner "root"
      group "root"
      variables({
         :app => app,
         :env => env_hash,
      })
    end

  else
    # aplicamos a migracion
    rvm_shell "exec_db_migration" do    
        user        app["owner"]
        group       app["group"]
        cwd         app["target_path"]
        environment env_hash
        code        app["migration_command"]
        only_if     {app["migrate"] == "yes"}
    end

    # agora temos o recurso "bash" parcheado para que utilice rvm_shell como provider
    bash "postdeploy" do    
        user        app["owner"]
        group       app["group"]
        cwd         app["target_path"]
        environment env_hash
        code        %{bash #{app["target_path"]}/#{app["postdeploy_script"]}}
        only_if     do
          not app["postdeploy_script"].nil? and
          not app["postdeploy_script"].empty? and 
          ::File.exists?("#{app["target_path"]}/#{app["postdeploy_script"]}")
        end
    end
  end


  # configuramos o frontend + backend
  nginx_passenger_site app["domain"] do
    static_files_path   "#{app["target_path"]}/public"
    rack_env            app["environment"]
    server_alias        app["alias"] if app["alias"]
  end


end
