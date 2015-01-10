# dependencias para poder usar o lwrp
include_recipe "lang_ruby::install"
include_recipe "appserver_nginx::with_passenger"
include_recipe "code_repo::default"
