#require_relative 'provider_riyic_app.rb'

class Chef

    class Provider
        
        class RackApp < Chef::Provider::RiyicApp

            def env_hash
                # variables de entorno
                {
                  "RACK_ENV"  => new_resource.environment,
                  "RAILS_ENV" => new_resource.environment,
                  "MERB_ENV"  => new_resource.environment
                }

            end

            def install_dependencies
                code =  %{bundle install --deployment --binstubs}
                code << %{ --without #{new_resource.exclude_bundler_groups.join(' ')}} if new_resource.exclude_bundler_groups.any?

#                rvm_shell "bundle install" do    
                 bash "bundle install" do
                    user        new_resource.owner
                    group       new_resource.group
                    cwd         new_resource.target_path

                    environment env_hash
                    ## fundamental meter o --path dentro do propio deploy, senon trata de instalar no home do usuario que lance o sudo
                    ## code        %{bundle install --path=vendor/bundle --binstubs --without #{app["exclude_bundler_groups"].join(' ')}}
                    code        code

                end

                # modulos que non estan no requirements
                Array(new_resource.extra_gems).each do |p|
                    (name,version) = p.split('#')

                    rvm_gem name do
                        action :install
                        version version if version
                    end
                end
            end


            def migrate_db
                return unless new_resource.migration_command

                if node["riyic"]["inside_container"]
                    template "/root/extra_tasks.sh" do
                      source "extra_tasks.sh.erb"
                      mode "700"
                      owner "root"
                      group "root"
                      variables({
                         :app => new_resource,
                         :env => env_hash,
                      })
                    end

                else
                    # aplicamos a migracion
                    #rvm_shell "exec_db_migration" do    
                    bash "exec_db_migration" do
                        user        new_resource.owner
                        group       new_resource.group
                        cwd         new_resource.target_path
                        environment env_hash
                        code        new_resource.migration_command
                    end

                end

            end

            def configure_backend
            end

            def configure_frontend
                # configuramos backend + frontend
                nginx_passenger_site new_resource.domain do
                    server_alias        new_resource.server_alias
                    document_root       new_resource.target_path + '/public'
                    static_files_path   new_resource.target_path + '/public'
                    rack_env            new_resource.environment
                end

            end
        end

    end

end


