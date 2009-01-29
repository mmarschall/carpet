require File.dirname(__FILE__) + '/../spec_helper'

describe "admin plugin" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @adm = @config.adm
    @adm.stub!(:pfexec)
    @adm.stub!(:run)
    @adm.stub!(:put)
    keys = <<-KEYS
ssh-dss AAAAB3NzaC1kcjRk4= ca@example.com
  KEYS
    @adm.stub!(:keys).and_return(keys)
  end
  
  describe "- user_exists? method" do
    it "should return true, if the user exists" do
      @adm.should_receive(:capture).with("cat /etc/passwd", {}).and_return("nobody:x:60001:60001:NFS Anonymous Access User:/:\ndepp:x:101::/export/home/depp:/usr/bin/bash\n")
      @adm.user_exists?("depp").should be(true)
    end
    
    it "should return false, if user does not exist" do
      @adm.should_receive(:capture).with("cat /etc/passwd", {}).and_return("nobody:x:60001:60001:NFS Anonymous Access User:/:\nmm:x:101::/export/home/mm:/usr/bin/bash\n")
      @adm.user_exists?("depp").should be(false)
    end
  end
  
  describe "- useradd method" do
    before do
      @adm.stub!(:assure)
      @adm.stub!(:unlock_user)
      @adm.stub!(:ssh_keys)
      @adm.stub!(:user_exists?)
    end
    
    it "should assure that the /export/home directory is there to be able to create the user's home dir within it" do
      @adm.should_receive(:assure).with(:directory, "/export/home", {})
      @adm.useradd("apl")
    end
    
    it "should add the user, if user does not exist" do
      @adm.stub!(:user_exists?).and_return(false)
      @adm.should_receive(:pfexec).with("/usr/sbin/useradd -d /export/home/apl -m -g staff -s /usr/bin/bash apl", {})
      @adm.useradd("apl")
    end
    
    it "should not try to add the user if existing" do
      @adm.stub!(:user_exists?).and_return(true)
      @adm.should_not_receive(:pfexec).with("/usr/sbin/useradd -d /export/home/apl -m -s /usr/bin/bash apl", {})
      @adm.useradd("apl")
    end
    
    it "should not unlock the user, if default_password_hash not set" do
      @adm.should_not_receive(:unlock_user)
      @adm.useradd("apl")
    end
    
    it "should unlock the user if default_password_hash is set" do
      @adm.stub!(:exists?).with(:default_password_hash).and_return(true)
      @adm.stub!(:default_password_hash).and_return("ASDF&$§")
      @adm.should_receive(:unlock_user).with("apl", "ASDF&$§", {})
      @adm.useradd("apl")
    end
    
    it "should set the ssh keys for the user" do
      @adm.should_receive(:ssh_keys).with("apl", @adm.keys, {:group => "staff"})
      @adm.useradd("apl")
    end
  end
  
  describe "- ssh_keys method" do
    it "should assure the .ssh dir  and the authorized_keys file for the user" do
      @adm.should_receive(:assure).with(:directory, "/export/home/apl/.ssh", {:mode => "700", :owner => "apl"})
      @adm.should_receive(:assure).with(:file, "/export/home/apl/.ssh/authorized_keys", @adm.keys, {:mode => "600", :owner => "apl"})
      @adm.ssh_keys("apl", @adm.keys)
    end
  end
  
  describe "- enable_ntp method" do
    before do
      @svc = @config.svc
      @svc.stub!(:enable)
      @svc.stub!(:online?)
      @svc.stub!(:run)
      @adm.stub!(:assure)
    end
    
    it "should configure the ntp client settings" do
      @adm.should_receive(:assure).with(:file, "/etc/inet/ntp.conf", "server my.ntp.host")
      @adm.enable_ntp("my.ntp.host")
    end
    
    it "should try to set the current date, if the ntp service is not running" do
      @svc.stub!(:online?).and_return(false)
      @adm.should_receive(:pfexec).with("/usr/sbin/ntpdate my.ntp.host", {})
      @adm.enable_ntp("my.ntp.host")
    end
    
    it "should not attempt to set the current date, if the ntp service is already running" do
      @svc.stub!(:online?).and_return(true)
      @adm.should_not_receive(:pfexec).with("/usr/sbin/ntpdate my.ntp.host", {})
      @adm.enable_ntp("my.ntp.host")
    end

    it "should enable all required services" do
      @svc.stub!(:online?).and_return(false)
      @svc.should_receive(:enable).with("network/dns/multicast", {})
      @svc.should_receive(:enable).with("network/ntp", {})
      @adm.enable_ntp("my.ntp.host")
    end

    it "should not try to enable all required services, if ntp is already running" do
      @svc.stub!(:online?).and_return(true)
      @svc.should_not_receive(:enable).with("network/dns/multicast", {})
      @svc.should_not_receive(:enable).with("network/ntp", {})
      @adm.enable_ntp("my.ntp.host")
    end
  end
  
  describe "- unlock_user method" do
    it "should set the given password for the user to unlock her account" do
      @adm.stub!(:capture).and_return("asdf\napl:*LK*:asdf")
      @adm.should_receive(:assure).with(:file, "/etc/shadow", "asdf\napl:ASDF§$&:asdf", {})
      @adm.unlock_user("apl", "ASDF§$&")
    end
  end
  
  describe "- chgrp method" do
    it "should change the group of the given path recursively" do
      @adm.should_receive(:pfexec).with("/usr/bin/chgrp -R users /blah", {:group => "users"})
      @adm.chgrp("/blah", :group => "users")
    end
    
    it "should not attempt to change the group if no group given" do
      @adm.should_not_receive(:pfexec)
      @adm.chgrp("/blah")
    end
  end
  
  describe "- chown method" do
    it "should change the owner of a path recursively" do
      @adm.should_receive(:pfexec).with("/usr/bin/chown -R apl /blah", {:owner => "apl"})
      @adm.chown("/blah", :owner => "apl")
    end
    it "should not attempt to change the owner if none given" do
      @adm.should_not_receive(:pfexec)
      @adm.chown("/blah")
    end
  end
  
  describe "- chmod method" do
    it "should change the permissions of a given path recursively" do
      @adm.should_receive(:pfexec).with("/usr/bin/chmod -R 700 /blah", {:mode => "700"})
      @adm.chmod("/blah", :mode => "700")
    end
    it "should not attempt to change the permissions if none given" do
      @adm.should_not_receive(:pfexec)
      @adm.chmod("/blah")
    end
  end
  
  describe "- ln method" do
    it "should try to create a softlink" do
      @adm.should_receive(:pfexec).with("/usr/bin/ln -nfs shared/config.rb release", {})
      @adm.ln("shared/config.rb", "release")
    end
  end
  
  describe "- mkdir method" do
    
    before do
      @adm.stub!(:path_exists?).and_return(false)
    end
    
    it "should not attempt to create a directory if it is there already" do
      @adm.should_receive(:path_exists?).with("/blub", {}).and_return(true)
      @adm.should_not_receive(:pfexec).with("mkdir -p /blug", {})
      @adm.mkdir("/blub")
    end
    
    it "should set the mode if given when creating" do
      @adm.should_receive(:pfexec).with("mkdir -m 644 -p /blub", {:mode => "644"})
      @adm.mkdir("/blub", :mode => "644")
    end
    
    it "should set the owner if given" do
      @adm.should_receive(:chown).with("/blub", {:owner => "apl"})
      @adm.mkdir("/blub", :owner => "apl")
    end
    
    it "should set the group if given" do
      @adm.should_receive(:chgrp).with("/blub", {:group => "users"})
      @adm.mkdir("/blub", :group => "users")
    end

    it "should change the mode if given" do
      @adm.should_receive(:chmod).with("/blub", {:mode => "700"})
      @adm.mkdir("/blub", :mode => "700")
    end
  end
  
  describe "- path_exists? method" do
    it "should try to find the given path" do
      @adm.should_receive(:chkdir).with("/zones/web1/root", {})
      @adm.path_exists?("/zones/web1/root")
    end
    
    it "should return false, if file or dir does not exist" do
      @adm.stub!(:chkdir).and_return(false)
      @adm.path_exists?("/zones/web1/root").should be(false)
    end
    
    it "should return true, if the file or dir does exist" do
      @adm.stub!(:chkdir).and_return(true)
      @adm.path_exists?("/zones/web1/root").should be(true)
    end
  end
  
  describe "- chkdir method" do
    it "should return true if path is found" do
      @adm.stub!(:capture).and_return("drwxr-xr-x   3 root     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root").should be(true)
    end
    
    it "should return true, if given owner does own the dir" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 apl     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:owner => "apl"}).should be(true)
    end
    
    it "should return true, if given group does own the dir" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 root     staff           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:group => "staff"}).should be(true)
    end
    
    it "should return true, if the dir does have the given permissions" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 root     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:mode => "755"}).should be(true)
    end

    it "should return true, if the dir does have all given attributes" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 apl     staff           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:mode => "755", :owner => "apl", :group => "staff"}).should be(true)
    end
    
    it "should return true, if owner and mode are given and fitting (group not given)" do
      @adm.should_receive(:capture).and_return("drwxrwxr-x   3 apl     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:owner=>"apl", :mode=>775}).should be(true)
    end

    it "should return false, if does not exist" do
      @adm.stub!(:capture).and_raise(Capistrano::CommandError)
      @adm.chkdir("/zones/web1/root/file.txt").should be(false)
    end

    it "should return false, if given owner does not own the dir" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 root     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:owner => "apl"}).should be(false)
    end
    
    it "should return false, if given group does not own the dir" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 root     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:group => "staff"}).should be(false)
    end
    
    it "should return false, if the dir does not have the given permissions" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 root     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:mode => "600"}).should be(false)
    end

    it "should return false, if the dir does not have the given permissions even though it has the given owner" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 root     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:mode => "600", :owner => "root"}).should be(false)
    end

    it "should return false, if the dir does not have the given permissions nor the given owner" do
      @adm.should_receive(:capture).and_return("drwxr-xr-x   3 root     root           3 Nov 18 16:55 /zones/web1/root\n")
      @adm.chkdir("/zones/web1/root", {:mode => "600", :owner => "root"}).should be(false)
    end
  end
end
