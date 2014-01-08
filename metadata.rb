name             "app_ruby"
maintainer       "RIYIC"
maintainer_email "info@riyic.com"
license          "Apache 2.0"
description      "Cookbook to deploy ruby applications"
#long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"

## Imprescindible en chef 11!!!
depends "lang_ruby"
depends "lang_nodejs"

depends "dbs_mysql"
depends "appserver_nginx"
depends "code_repo"

depends "build-essential"

%w{debian ubuntu}.each do |os|
  supports os
end

recipe "default",
    description: "empty",
    attributes: []


#deploy_rails_app
recipe "deploy_rails_app",
    description: "Install rails application from repository",
    attributes: [/^apps\/rails\//],
    dependencies: ["appserver_nginx::with_passenger", "lang_nodejs", "lang_ruby::install"]

recipe "rack_app",
    description: "Deploy rack app from repository with nginx+passenger support",
    attributes: [/^app\/ruby\/rack_apps\//],
    dependencies: ["lang_ruby::install", "appserver_nginx::with_passenger"],
    stackable: true

attribute "app/ruby/rack_apps/@/domain",
    :display_name => 'Application domain',
    :description => 'Domain associated to app virtual host',
    :default => 'test.com',
    :advanced => false,
    :required => true,
    :validations => {predefined: "domain"}

attribute "app/ruby/rack_apps/@/alias",
    :display_name => 'Application alias',
    :description => 'Optional server names to webserver can route request to application, wildcards (*) are permitted',
    :default => [],
    :advanced => false,
    :required => false,
    :type => "array",
    :validations => {predefined: "server_name"}

attribute "app/ruby/rack_apps/@/environment",
    :display_name => 'Application environment',
    :description => 'Application Environment',
    :default => 'production',
    :advanced => false,
    :required => true,
    :validations => {predefined: "word"}

attribute "app/ruby/rack_apps/@/target_path",
    :display_name => "Application deployment folder",
    :description => 'The application will be deployed to this folder',
    :default => '/home/owner/my_app',
    :advanced => false,
    :validations => {predefined: "unix_path"}

attribute "app/ruby/rack_apps/@/owner",
    :display_name => "Deployment owner",
    :description => 'User that shall own the target path',
    :default => 'owner',
    :advanced => false,
    :validations => {predefined: "username"}

attribute "app/ruby/rack_apps/@/group",
    :display_name => "Deployment group",
    :description => 'The group that shall own the target path',
    :default => 'ownergrp',
    :validations => {predefined: "username"}


# attribute "app/ruby/rack_apps/@/database_type",
#     :display_name => "Application database type",
#     :description => 'Application database type ( sqlite, mysql, postgresql, mongodb)',
#     :default => 'mysql',
#     :advanced => false,
#     :choice => ["sqlite", "mysql","pgsql","mongodb"]


attribute "app/ruby/rack_apps/@/repo_url",
    :display_name => 'Repository source code url',
    :description => 'Repository url from which to download source code',
    :advanced => false,
    :required => true,
    :default => "http://my-repo-url.com",
    :validations => {predefined: "url"}


attribute "app/ruby/rack_apps/@/repo_type",
    :display_name => "Repository type",
    :description => 'Repository type from which to download application code',
    :default => 'git',
    :advanced => false,
    :choice => ["git", "subversion","remote_archive"]

attribute "app/ruby/rack_apps/@/revision",
    :display_name => 'Application Repository revision',
    :description => 'Application repository tag/branch/commit/archive_name to download',
    :default => "HEAD",
    :validations => {predefined: "revision"}

attribute "app/ruby/rack_apps/@/migrate",
    :display_name => 'Apply migrations?',
    :description => 'If "yes" migrations will be run',
    :advanced => false,
    :choice => ["yes","no"],
    :default => "yes",
    :required => true

attribute "app/ruby/rack_apps/@/migration_command",
    :display_name => 'Migration command',
    :description => 'Command to run to migrate application to current state',
    :default => "bundle exec rake db:migrate",
    :validations => {predefined: "unix_command"}

# attribute "app/ruby/rack_apps/@/remote_user",
#     :display_name => 'Repository remote user',
#     :description => 'Application repository remote user',
#     :validations => {predefined: "user"}

attribute "app/ruby/rack_apps/@/credential",
    :display_name => 'Repository remote user credential',
    :description => 'Application repository remote user credential',
    :field_type => 'textarea',
    :validations => {predefined: "multiline_text"}

# attribute "app/ruby/rack_apps/@/repo_private_key",
#     :display_name => 'Application repository private key',
#     :description => 'Application repository private_key to access',
#     :field_type => 'textarea',
#     :validations => {predefined: "multiline_text"}

attribute "app/ruby/rack_apps/@/extra_packages",
    :display_name => 'System extra packages needed',
    :description => 'System extra packages needed for the application',
    :type => "array",
    :default => [],
    :validations => {predefined: "package_name"}

attribute "app/ruby/rack_apps/@/postdeploy_script",
    :display_name => 'Bash script with extra tasks to run',
    :description => 'Script with extra tasks to run after deploy (relative path from target_path)',
    :default => "",
    :validations => {predefined: "unix_path"}

attribute "app/ruby/rack_apps/@/exclude_bundler_groups",
    :display_name => 'Groups to exclude in bundler',
    :description => 'List of groups to exclude at "bundler install"',
    :type => "array",
    :validations => {predefined: "word"}


#old 
attribute "apps/rails/domain",
    :display_name => 'Application domain',
    :description => 'Domain associated to app virtual host',
    :default => 'test.com',
    :advanced => false,
    :validations => {predefined: "domain"}

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
    :validations => {predefined: "unix_path"}

attribute "apps/rails/user",
    :display_name => "Application system user",
    :description => 'System user to run application',
    :default => 'app',
    :validations => {predefined: "username"}

attribute "apps/rails/group",
    :display_name => "Application system group",
    :description => 'System group to run application',
    :default => 'app',
    :validations => {predefined: "username"}

attribute "apps/rails/homedir",
    :display_name => "Application system user homedir",
    :description => 'Application system user homedir',
    :default => '/home/app',
    :validations => {predefined: "unix_path"}

attribute "apps/rails/database/name",
    :display_name => "Application database name",
    :description => 'Application database name (only to mysql or postgresql)',
    :default => 'app',
    :validations => {predefined: "mysql_dbname"},
    :advanced => false

attribute "app/rails/database/username",
    :display_name => "Application database username",
    :description => 'Application database username (only to mysql or postgresql)',
    :default => 'app',
    :validations => {predefined: "mysql_dbuser"},
    :advanced => false

attribute "apps/rails/database/password",
    :display_name => "Application Database Password" ,
    :description => "Database password for the application installation",
    :calculated => true,
    :validations => {predefined: "db_password"}

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
    :validations => {predefined: "host"}

attribute "apps/rails/source/repo/url",
    :display_name => 'App repository url of source code',
    :description => 'App repository from which to download source code',
    :advanced => false,
    :required => true,
    :default => "http://my-repo-url.com",
    :validations => {predefined: "url"}

attribute "apps/rails/source/repo/reference",
    :display_name => 'Application Repository reference',
    :description => 'Application repository tag/branch/commit to download',
    :advanced => false,
    :default => "master",
    :required => true,
    :validations => {predefined: "revision"}

attribute "apps/rails/source/repo/private",
    :display_name => 'Is Application Repository Private?',
    :description => 'Is application repository private?',
    :default => "false",
    :choice => ["true","false"]

attribute "apps/rails/source/repo/priv_key",
    :display_name => 'Application repository private key',
    :description => 'Application repository private_key to access',
    :field_type => 'textarea',
    :validations => {predefined: "multiline_text"}

attribute "apps/rails/deploy_to",
    :display_name => "deploy_to directory",
    :description => 'Directory to where deploy app source code',
    :default => '/home/app/deploy',
    :validations => {predefined: "unix_path"}
