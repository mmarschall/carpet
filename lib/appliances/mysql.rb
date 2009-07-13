Capistrano::Configuration.instance(:must_exist).load do 
  task :mysql do
    needs :database
    needs :database_backup
    needs :mysql_slave_config if current_node.options[:mysql_slave]
  end
  
  task :database do
    assure(:file, "/etc/mysql/5.0/my.cnf", render(mysql_conf_file, {:mysql_server_id => current_node.options[:mysql_server_id]})) if exists?(:mysql_conf_file)
    assure(:package, "SUNWmysql5")
    svc.setprop("svc:/application/database/mysql:version_50", "mysql/enable_64bit", "true")
    svc.enable("svc:/application/database/mysql:version_50")
    sleep(5) # give mysql server time to start up (service is online before mysql is fully started - especially InnoDB takes a couple seconds)
    pfexec("/usr/mysql/bin/mysqladmin -u root password #{mysql_root_password} || exit 0") if exists?(:mysql_root_password)
    sql = "grant replication slave, replication client on *.* to '#{db_user}'@'%' identified by '#{db_password}' ;"
    invoke_command("/usr/mysql/bin/mysql -u root --password=#{mysql_root_password} --execute \"#{sql}\"")
  end
  
  task :database_backup do
    ftp_backup_host = current_node.options[:ftp_backup_host]
    ftp_user = current_node.options[:ftp_user]
    ftp_password = current_node.options[:ftp_password]
    enable_backup = current_node.options[:enable_ftp_backup]
    if ftp_backup_host && ftp_user && ftp_password
      logger.info("Setting up daily mysqldump backup for database '#{db_name}' to FTP server '#{ftp_backup_host}' with user '#{ftp_user}'")
      assure :file, "/export/home/#{application_user}/.netrc", "machine #{ftp_backup_host} login #{ftp_user} password #{ftp_password}", :mode => 600
      backup_sh = <<-EOSH
#!/bin/sh
FILE=mysql-#{db_name}-$(date +"%d-%m-%Y-%Hh%Mm%Ss").sql.gz
/usr/mysql/bin/mysqldump -u root -h localhost -p#{mysql_root_password} --flush-logs #{db_name} | /usr/bin/gzip -9 > $FILE
ftp #{ftp_backup_host} <<EOF
put $FILE $FILE
quit
EOF
rm $FILE
exit 0
      EOSH
      assure :file, "/export/home/#{application_user}/backup.sh", backup_sh, :mode => 755

      if current_node.options[:primary] && enable_backup
        assure :file, "my_crontab", "13 3 * * * /export/home/#{application_user}/backup.sh >> /export/home/#{application_user}/mysql_backup.log 2>&1"
        invoke_command("crontab my_crontab; rm my_crontab")
      end
    else
      puts("Database backup not setup. Please set 'ftp_backup_host', 'ftp_user', and 'ftp_password' in your Capfile!")
    end
  end
  
  task :mysql_slave_config do
    assure(:file, "/usr/local/nagios/libexec/check_mysql_slave.sh", File.read("#{File.dirname(__FILE__)}/../../resources/nagios-plugins/check_mysql_slave.sh"), :mode => 755)
    if slave_status("Slave_IO_Running") == "No"
      sql = "CHANGE MASTER TO MASTER_HOST='#{current_node.options[:mysql_master_host]}', MASTER_USER='#{db_user}', MASTER_PASSWORD='#{db_password}' ;"
      invoke_command("/usr/mysql/bin/mysql -u root --password=#{mysql_root_password} --execute \"#{sql}\"")
    end
  end

  def slave_status(key)
    sql = "SHOW SLAVE STATUS\\G"
    slave_status = capture("/usr/mysql/bin/mysql -u root --password=#{mysql_root_password} --execute \"#{sql}\"")
    lines = slave_status.split("\n")
    lines.each do |line|
      value = ""
      value = line.strip.split(":")[1] if line.strip.split(":")[0] == key
      return value.strip
    end
  end
end