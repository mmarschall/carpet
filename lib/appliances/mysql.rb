Capistrano::Configuration.instance(:must_exist).load do 
  task :mysql do
    needs :database
    needs :database_backup
  end
  
  task :database do
    assure :package, "SUNWmysql5"
    svc.setprop("svc:/application/database/mysql:version_50", "mysql/enable_64bit", "true")
    sleep(5) # give mysql server time to start up (service is online before mysql is fully started - especially InnoDB takes a couple seconds)
    pfexec("/usr/mysql/bin/mysqladmin -u root password #{mysql_root_password} || exit 0") if exists?(:mysql_root_password)
  end
  
  task :database_backup do
    if ftp_backup_host && ftp_user && ftp_password
      logger.info("Setting up daily mysqldump backup for database '#{db_name}' to FTP server '#{ftp_backup_host}' with user '#{ftp_user}'")
      assure :file, "/export/home/#{application_user}/.netrc", "machine #{ftp_backup_host} login #{ftp_user} password #{ftp_password}", :mode => 600
      backup_sh = <<-EOSH
        #!/bin/sh
        FILE=mysql-#{db_name}-$(date +"%d-%m-%Y-%Hh%Mm%Ss").sql.gz
        /usr/mysql/bin/mysqldump -u root -h localhost -p#{mysql_root_password} --flush-logs #{db_name} | /usr/bin/gzip -9 > /tmp/$FILE
        ftp #{ftp_backup_host} <<EOF
        put /tmp/$FILE $FILE
        quit
        EOF
        rm /tmp/$FILE
        exit 0
      EOSH
      assure :file, "/export/home/#{application_user}/backup.sh", backup_sh, :mode => 755
    
      assure :file, "my_crontab", "13 3 * * * /export/home/#{application_user}/backup.sh > /export/home/#{application_user}/mysql_backup.log 2>&1"
      invoke_command("crontab my_crontab; rm my_crontab")
    else
      logger.warn("Database backup not setup. Please set 'ftp_backup_host', 'ftp_user', and 'ftp_password' in your Capfile!")
    end
  end
end