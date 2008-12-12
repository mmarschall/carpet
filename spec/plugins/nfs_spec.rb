require File.dirname(__FILE__) + '/../spec_helper'

describe "nfs plugin" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @nfs = @config.nfs
    @nfs.stub!(:run)
    @nfs.stub!(:assure)
    @nfs.stub!(:put)
    @nfs.stub!(:pfexec)
    @nfs.stub!(:capture).and_return("")
  end
  
  it "should be able to enable the nfs client service and its dependencies" do
    @svc = @config.svc
    @svc.should_receive(:enable).with("network/nfs/nlockmgr", {}).ordered
    @svc.should_receive(:enable).with("network/nfs/status", {}).ordered
    @svc.should_receive(:enable).with("network/nfs/client", {}).ordered
    @nfs.enable_client
  end
  
  describe "- mounted? method" do
    it "should return false, if mountpoint is not in use" do
      @nfs.stub!(:capture).and_return("")
      @nfs.mounted?("bla").should be(false)
    end
    
    it "should return true, if the mountpoint is in use" do
      @nfs.stub!(:capture).and_return("/export/home/apl/shared/public/images/users on 10.0.0.100:/export/autoplenum/users remote/read/write/setuid/nodevices")
      @nfs.mounted?("/export/home/apl/shared/public/images/users").should be(true)
    end
  end
  
  describe "- mount method" do
    before do
      @nfs.stub!(:enable_client)
      @nfs.stub!(:mounted?).and_return(false)
    end
    
    it "should assure the mountpoint is there" do
      @nfs.should_receive(:assure).with(:directory, "/mnt/mydir")
      @nfs.mount("10.20.2.333:/export/mydir", "/mnt/mydir")
    end
    
    it "should attempt to mount the share, if it is not already mounted" do
      @nfs.should_receive(:pfexec).with("/usr/sbin/mount -F nfs 10.20.2.333:/export/mydir /mnt/mydir", {})
      @nfs.mount("10.20.2.333:/export/mydir", "/mnt/mydir")
    end
    
    it "should not try to mount the share, if it is already mounted" do
      @nfs.stub!(:mounted?).and_return(true)
      @nfs.should_not_receive(:pfexec)
      @nfs.mount("10.20.2.333:/export/mounteddir", "/mnt/mounteddir")
    end
    
    it "should not attempt to add the mount to vfstab, if it is already there" do
      vfstab = <<-TAB
#device         device          mount           FS      fsck    mount   mount
#to mount       to fsck         point           type    pass    at boot options
#
/devices        -               /devices        devfs   -       no      -
/proc           -               /proc           proc    -       no      -
ctfs            -               /system/contract ctfs   -       no      -
objfs           -               /system/object  objfs   -       no      -
sharefs         -               /etc/dfs/sharetab       sharefs -       no      -
fd              -               /dev/fd         fd      -       no      -
swap            -               /tmp            tmpfs   -       yes     -
10.20.2.333:/export/mydir    -       /mnt/mydir     nfs     -       yes     -
      TAB
      @nfs.stub!(:capture).with("cat /etc/vfstab", {}).and_return(vfstab)
      @nfs.should_receive(:assure).with(:file, "/etc/vfstab", vfstab.strip)
      @nfs.mount("10.20.2.333:/export/mydir", "/mnt/mydir")
    end

    it "should add the mount to vfstab, if it is not there" do
      vfstab_old = <<-TAB
#device         device          mount           FS      fsck    mount   mount
#to mount       to fsck         point           type    pass    at boot options
#
/devices        -               /devices        devfs   -       no      -
/proc           -               /proc           proc    -       no      -
ctfs            -               /system/contract ctfs   -       no      -
objfs           -               /system/object  objfs   -       no      -
sharefs         -               /etc/dfs/sharetab       sharefs -       no      -
fd              -               /dev/fd         fd      -       no      -
swap            -               /tmp            tmpfs   -       yes     -
      TAB
      
      vfstab_new = <<-TAB
#device         device          mount           FS      fsck    mount   mount
#to mount       to fsck         point           type    pass    at boot options
#
/devices        -               /devices        devfs   -       no      -
/proc           -               /proc           proc    -       no      -
ctfs            -               /system/contract ctfs   -       no      -
objfs           -               /system/object  objfs   -       no      -
sharefs         -               /etc/dfs/sharetab       sharefs -       no      -
fd              -               /dev/fd         fd      -       no      -
swap            -               /tmp            tmpfs   -       yes     -\n10.20.2.333:/export/mydir\t-\t/mnt/mydir\tnfs\t-\tyes\t-
TAB
      @nfs.stub!(:capture).with("cat /etc/vfstab", {}).and_return(vfstab_old)
      @nfs.should_receive(:assure).with(:file, "/etc/vfstab", vfstab_new)
      @nfs.mount("10.20.2.333:/export/mydir", "/mnt/mydir")
    end
    
    it "should make sure that the nfs client is enabled so that the entries in vfstab are actually used at boot time" do
      @nfs.should_receive(:enable_client).with({})
      @nfs.mount("10.20.2.333:/export/mydir", "/mnt/mydir")
    end
  end
end