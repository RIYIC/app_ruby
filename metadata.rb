name             "app_ruby"
maintainer       "RIYIC"
maintainer_email "info@riyic.com"
license          "Apache 2.0"
description      "Cookbook to deploy ruby applications"
#long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

## Imprescindible en chef 11!!!
depends "lang_ruby"
depends "lang_nodejs"

depends "dbsystem_mysql"
depends "appserver_nginx"

%w{debian ubuntu}.each do |os|
  supports os
end

recipe "default",
    description: "empty",
    attributes: []


#deploy_rails_app
recipe "deploy_rails_app",
    description: "Install rails application from repository",
    attributes: [/apps\/rails\/.+/],
    dependencies: ["appserver_nginx::with_passenger", "lang_nodejs", "lang_ruby::install"]


attribute "apps/rails/domain",
    :display_name => 'Application domain',
    :description => 'Domain associated to app virtual host',
    :default => 'test.com',
    :advanced => false,
    :validations => {fixed: "domain"}

attribute "apps/rails/environment",
    :display_name => 'Application environment',
    :description => 'Application Environment',
    :default => 'production',
    :choice => ["production", "test", "development"]

attribute "apps/rails/dir",
    :display_name => "Application document_root directory",
    :description => 'Document_root directory where to point virtualhost',
    :default => '/home/app/doc_root',
    :advanced => false,
    :validations => {fixed: "unix_path"}

attribute "apps/rails/user",
    :display_name => "Application system user",
    :description => 'System user to run application',
    :default => 'app',
    :validations => {fixed: "username"}

attribute "apps/rails/group",
    :display_name => "Application system group",
    :description => 'System group to run application',
    :default => 'app',
    :validations => {fixed: "username"}

attribute "apps/rails/homedir",
    :display_name => "Application system user homedir",
    :description => 'Application system user homedir',
    :default => '/home/app',
    :validations => {fixed: "unix_path"}

attribute "apps/rails/database/name",
    :display_name => "Application database name",
    :description => 'Application database name (only to mysql or postgresql)',
    :default => 'app',
    :validations => {fixed: "mysql_dbname"},
    :advanced => false

attribute "app/rails/database/username",
    :display_name => "Application database username",
    :description => 'Application database username (only to mysql or postgresql)',
    :default => 'app',
    :validations => {fixed: "mysql_dbuser"},
    :advanced => false

attribute "apps/rails/database/password",
    :display_name => "Application Database Password" ,
    :description => "Database password for the application installation",
    :calculated => true,
    :validations => {regex: /\A\w+\z/}

attribute "apps/rails/database/type",
    :display_name => "Application database type",
    :description => 'Application database type ( sqlite, mysql or postgresql)',
    :default => 'sqlite',
    :advanced => false,
    :choice => ["sqlite", "mysql"]

attribute "apps/rails/database/hostname",
    :display_name => "App database hostname",
    :description => 'Application database hostname (only to mysql or postgresql)',
    :default => 'localhost',
    :validations => {fixed: "host"}

attribute "apps/rails/source/repo/url",
    :display_name => 'App repository url of source code',
    :description => 'App repository from which to download source code',
    :advanced => false,
    :required => true,
    :validations => {fixed: "url"}

attribute "apps/rails/source/repo/reference",
    :display_name => 'Application Repository reference',
    :description => 'Application repository tag/branch/commit to download',
    :advanced => false,
    :required => true,
    :validation => {regex: /\w+/}

attribute "apps/rails/source/repo/private",
    :display_name => 'Is Application Repository Private?',
    :description => 'Is application repository private?',
    :default_value => "false",
    :choice => ["true","false"]

attribute "apps/rails/source/repo/priv_key",
    :display_name => 'Application repository private key',
    :description => 'Application repository private_key to access',
    :validation => {regex: /\w+/}

attribute "apps/rails/deploy_to",
    :display_name => "deploy_to directory",
    :description => 'Directory to where deploy app source code',
    :default => '/home/app/deploy',
    :validations => {fixed: "unix_path"}
