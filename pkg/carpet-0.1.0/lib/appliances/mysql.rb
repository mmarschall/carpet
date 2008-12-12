Capistrano::Configuration.instance(:must_exist).load do 
  task :mysql do
    assure :package, "SUNWmysql5"
    svc.enable("svc:/application/database/mysql:version_50")
    pfexec("/usr/mysql/bin/mysqladmin -u root password #{mysql_root_password} || exit 0") if exists?(:mysql_root_password)
  end
end