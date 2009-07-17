require 'capistrano'

module Adm
  def mkdir(path, options={})
    logger.debug "mkdir(#{path}, #{options.inspect})"
    mode = options[:mode]
    owner = options[:owner]
    group = options[:group]
    mkdir_options = "" 
    mkdir_options << " -m #{mode}" if mode
    pfexec("mkdir#{mkdir_options} -p #{path}", options) unless path_exists?(path, options)
    chown(path, options.merge(:owner => owner))
    chgrp(path, options.merge(:group => group))
    chmod(path, options.merge(:mode => mode))
  end
  
  def path_exists?(path, options={})
    chkdir(path, options.dup)
  rescue Capistrano::CommandError
    false
  end
  
  def user_exists?(username, options={})
      capture("cat /etc/passwd", options).include?("#{username}:x:")
  end
  
  # useradd needs the variable 'keys' (the users ssh keys going to authorized_keys file) set and uses the following options:
  # :uid => e.g. 104, the user id (instead of assigning one automatically)
  # :profiles => e.g. "Primary Administrator", the profile the user should be able to use
  # :user_roles => e.g. "root", the roles the user should be part of
  # :group => e.g. "staff", the group the user should be part of
  # :no_keys => true, if set, the user will be installed without any keys (like a user for a service)
  # :sudoers => true, if set, the user will be added to the sudoers file enabling him to use sudo without password
  # It makes sure the user gets /usr/bin/bash as his shell and creates his home dir at /export/home
  # If you pass in :via => :zlogin, :zone => "bla" the user will created within the given zone
  def useradd(username, options={})
    uid_opts = options[:uid].nil? ? "" : " -u #{options[:uid]}"
    profile_opts = options[:profiles].nil? ? "" : " -P \"#{options.delete(:profiles)}\""
    role_opts = options[:user_roles].nil? ? "" : " -R \"#{options.delete(:user_roles)}\""
    group = options[:group] || "staff"
    assure(:directory, "/export/home", options)
    assure(:directory, "/export/home/#{username}", {:owner => username, :group => group, :mode => 755})
    pfexec("/usr/sbin/useradd -d /export/home/#{username}#{uid_opts}#{profile_opts}#{role_opts} -m -g #{group} -s /usr/bin/bash #{username}", options) unless user_exists?(username, options)
    unlock_user(username, default_password_hash, options) if exists?(:default_password_hash)
    ssh_keys(username, keys, options.merge(:group => group)) unless options[:no_keys]
    assure(:file, "/etc/sudoers", capture("pfexec cat /etc/sudoers", options) << "\n#{username} ALL=(ALL) NOPASSWD: ALL", options.merge(:mode => "440", :owner => "root", :group => "root")) if options[:sudoers]
  end
  
  def groupadd(groupname, options={})
    pfexec("/usr/sbin/groupadd #{groupname} || true", options)
  end
  
  def unlock_user(username, password, options={})
    assure(:file, "/etc/shadow", capture("pfexec cat /etc/shadow", options).gsub("#{username}:*LK*:", "#{username}:#{password}:"), options)
  end
  
  def ssh_keys(username, keys, options={})
    assure(:directory, "/export/home/#{username}/.ssh", options.merge(:mode => "700", :owner => username))
    assure(:file, "/export/home/#{username}/.ssh/authorized_keys", keys, options.merge(:mode => "600", :owner => username))
  end
  
  def chgrp(path, options={})
    logger.debug "chgrp(#{path}, #{options.inspect})"
    group = options[:group]
    pfexec("/usr/bin/chgrp -R #{group} #{path}", options) if group
  end
  
  def chown(path, options={})
    logger.debug "chown(#{path}, #{options.inspect})"
    owner = options[:owner]
    pfexec("/usr/bin/chown -R #{owner} #{path}", options) if owner
  end
  
  def chmod(path, options={})
    logger.debug "chmod(#{path}, #{options.inspect})"
    mode = options[:mode]
    pfexec("/usr/bin/chmod -R #{mode} #{path}", options) if mode
  end
  
  def chkdir(path, options={})
    logger.debug "chkdir(#{path}, #{options.inspect})"
    ls_ld = capture("pfexec ls -ld #{path}", options).strip.split(" ")
    owner = ls_ld[2]
    group = ls_ld[3]
    mode = octal_mode(ls_ld[0])
    owner_opt = options[:owner] || owner
    group_opt = options[:group] || group
    mode_opt = options[:mode] || mode
    group == group_opt && owner == owner_opt && mode == mode_opt.to_s
  rescue Capistrano::CommandError
    false
  end
  
  def ln(source_file, target_file, options={})
    cmd = "/usr/bin/ln -nfs #{source_file} #{target_file}"

    no_pfexec = options.delete(:no_pfexec)
    if no_pfexec == true
      run(cmd, options)
    else
      pfexec(cmd, options)
    end
  end
  
  def enable_ntp(server, options={})
    assure :file, "/etc/inet/ntp.conf", "server #{server}"
    pfexec("/usr/sbin/ntpdate #{server}", options) unless svc.online?("network/ntp", options)
    svc.enable("network/dns/multicast", options) unless svc.online?("network/dns/multicast", options)
    svc.enable("network/ntp", options) unless svc.online?("network/ntp", options)
  end
end

Capistrano.plugin :adm, Adm

def octal_mode(mode_str)
  u_r = mode_str[1,1] == "r" ? 4 : 0
  u_w = mode_str[2,1] == "w" ? 2 : 0
  u_x = mode_str[3,1] == "x" ? 1 : 0
  g_r = mode_str[4,1] == "r" ? 4 : 0
  g_w = mode_str[5,1] == "w" ? 2 : 0
  g_x = mode_str[6,1] == "x" ? 1 : 0
  o_r = mode_str[7,1] == "r" ? 4 : 0
  o_w = mode_str[8,1] == "w" ? 2 : 0
  o_x = mode_str[9,1] == "x" ? 1 : 0
  "#{u_r+u_w+u_x}#{g_r+g_w+g_x}#{o_r+o_w+o_x}"
end