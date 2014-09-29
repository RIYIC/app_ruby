# configuracions especificas de redmine con sqlite

# evitamos crear o ficheiro ca bd pq xa o supoñemos creado
# solo instalamos os paquetes necesarios
#

## sacado da default receta do cookbook sqlite 
# (O mellor deberiamos usalo????
case node['platform_family']
when "debian"

  package "sqlite3"
  package "sqlite3-doc"

when "rhel", "fedora"

  package 'sqlite-devel'

end
#####################################

gem_package "sqlite3-ruby"
