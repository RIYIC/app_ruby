#######################
# User
#######################

# Seria para usar de forma apilable, para poder facer o deploy de varias apps
node["app"]["ruby"]["rack_apps"].each do |app|


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


  #instalar paquetes de sistema necesarios
  if app["extra_packages"]
    app["extra_packages"].each do |pkg|
      package pkg
    end
  end

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
  end

  # todas as app rack deben ter un directorio tmp
  directory "#{app["target_path"]}/tmp" do
    owner app["owner"]
    group app["group"]
    recursive true
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
      code        %{bundle install --path=vendor/bundle --binstubs --without #{app["exclude_bundler_groups"].join(' ')}}
  end


  # aplicamos a migracion
  if app["migrate"] == "yes"

    rvm_shell "exec_db_migration" do    
      user        app["owner"]
      group       app["group"]
      cwd         "#{app["target_path"]}"
      environment env_hash
      code        app["migration_command"]
    end

  end


  # executamos script post deploy
  if app["postdeploy_script"]
    # rvm_shell "postdeploy" do    
    #     user        app["owner"]
    #     group       app["group"]
    #     cwd         app["target_path"]
    #     environment env_hash
    #     code        %{bash #{app["target_path"]}/#{app["postdeploy_script"]}}
    # end
    
    # co -l -c NON FAI FALTA meter o bash nun rvm_shell, pero ambos funcionan perfectamente
    bash "postdeploy" do    
        user        app["owner"]
        group       app["group"]
        cwd         app["target_path"]
        environment env_hash
        #code        %{bash -l -c #{app["target_path"]}/#{app["postdeploy_script"]}}
        code        %{bash #{app["target_path"]}/#{app["postdeploy_script"]}}
    end

  end


  # configuramos o frontend + backend
  nginx_passenger_site app["domain"] do
    static_files_path   "#{app["target_path"]}/public"
    rack_env            app["environment"]
  end

  # site = {"domain" => app["domain"],
  #         "document_root" => "#{app["target_path"]}/public"}

  # node.set['lang']['ruby']['rails']['sites'] = 
  #     node['lang']['ruby']['rails']['sites'] | [site]

  # include_recipe "appserver_nginx::add_passenger_site"

end
