## configuracions especificas da instalacion de redmine con mysql

# 1) supoñemos que a runlist ten que levar a instalacion do servidor mysql
# nalgun lado (nos vamos a contar con que temos disponible o atributo

include_recipe "dbs_mysql"
gem_package "mysql2"


# mysql_connection_info = {
#   :host =>  app['database']['hostname'],
#   :username => "root",
#   :password => node['mysql']['server_root_password']
# }

# mysql_database app['database']['name'] do
#     connection mysql_connection_info
#     action :create
# end

# #mysql_database "changing the charset of database" do
# #  connection mysql_connection_info
# #  database_name app['database']['name']
# #  action :query
# #  sql "ALTER DATABASE #{app['database']['name']} charset=latin1"
# #end

# #node.set_unless['redmine']['database']['password'] = secure_password

# mysql_database_user app['database']['username'] do
#   connection mysql_connection_info
#   password app['database']['password']
#   action :create
# end

# mysql_database_user app['database']['username'] do
#   connection mysql_connection_info
#   database_name app['database']['name']
#   privileges [
#     :all
#   ]
#   action :grant
# end

# mysql_database "flushing mysql privileges" do
#   connection mysql_connection_info
#   action :query
#   sql "FLUSH PRIVILEGES"
# end
