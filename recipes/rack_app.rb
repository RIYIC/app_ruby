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
  app["extra_packages"].each do |pkg|
    package pkg
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



  # # seteamos os parametros necesarios para descargar desde un repo ssh con key
  # if app["repo_private_key"]

  #     directory "#{owner_home}/.ssh" do
  #       owner app["owner"]
  #       group app["group"]
  #       mode '0700'
  #     end

  #     file "#{owner_home}/.ssh/id_rsa" do
  #         owner app["owner"]
  #         group app["group"]
  #         mode "0600"
  #         content app["repo_private_key"]
  #     end

  #     cookbook_file "#{owner_home}/gitssh.sh" do
  #         source "gitssh.sh"
  #         owner app["owner"]
  #         mode 00700
  #     end
  # end

  # #
  # # descargamos o codigo da app
  # #
  # if app["repo_type"] == "git"

  #   git "#{app["target_path"]}" do
  #     repository  app["repo_url"]
  #     reference   app["revision"]
  #     action      :sync
  #     user        app["owner"]
  #     group       app["group"]
  #     ssh_wrapper "#{owner_home}/gitssh.sh" if app["repo_private_key"]
  #   end

  # elsif app["repo_type"] == "subversion"

  #   subversion "" do
  #   end

  # elsif app["repo_type"] == "tar" ## remote file

  #   src_filepath  "#{Chef::Config['file_cache_path'] || '/tmp'}/archive.tar"
  #   remote_file app["repo_url"] do
  #     source   app["repo_url"]
  #     owner app["owner"]
  #     group app["group"]
  #     mode "0600"
  #     # checksum node['nginx']['source']['checksum']
  #     path     src_filepath
  #     backup   false
  #   end
  
  #   # hai que descomprimilo
  #   # as novas versions de tar detectan o tipo de compresion
  #   bash 'unarchive_source' do
  #     cwd  ::File.dirname(src_filepath)
  #     code <<-EOH
  #       tar xf #{::File.basename(src_filepath)} -C #{File.dirname(app["target_path"])}}
  #     EOH
  #     not_if { ::File.directory?("#{Chef::Config['file_cache_path'] || '/tmp'}/archive.tar") }
  #   end

  # elsif app["repo_type"] == "zip"

  # end


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

    rvm_shell "rake db:migrate" do    
            user        app["owner"]
            group       app["group"]
            cwd         "#{app["target_path"]}"
            environment env_hash
            code        "bundle exec rake db:migrate"
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
        code        %{bash -l -c #{app["target_path"]}/#{app["postdeploy_script"]}}
    end

  end


  # configuramos o frontend + backend
  # nginx_passenger_site do

  # end

  site = {"domain" => app["domain"],
          "document_root" => "#{app["target_path"]}/public"}

  node.set['lang']['ruby']['rails']['sites'] = 
      node['lang']['ruby']['rails']['sites'] | [site]

  include_recipe "appserver_nginx::add_passenger_site"

end
