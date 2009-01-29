Capistrano::Configuration.instance(:must_exist).load do 
  task :rails22 do
    rails_default_permissions = {:owner => application_user, :group => "staff", :mode => 775}
    assure :directory, "#{shared_path}", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/log", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config/environments", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/tmp", fetch(:default_permissions, rails_default_permissions)
    assure :match, "ruby --version", /1.8.7/ do
      src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz", :configure_opts => "--without-gcc")
    end
    assure :command, :git do
      src.install("http://kernel.org/pub/software/scm/git/git-1.6.1.tar.gz")
    end
    assure :match, "gem --version", "1.3.1" do
      src.install("http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz", :install_cmd => "pfexec ruby ./setup.rb")
    end
    assure :package, "SUNWimagick"
    assure :package, "SUNWmysql5"
    assure :package, "SUNWsvn"
    
    assure :gem, "hoe", "1.8.2"
    assure :gem, "mini_magick", "1.2.3"
    assure :gem, "rubyzip", "0.9.1"
    assure :gem, "rails", "2.2.2"
    patch_inflector_rb
    assure :gem, "memcache-client", "1.5.0"
    assure :gem, "fastercsv", "1.4.0"
    assure :gem, "mysql", "2.7", :gem_opts => "-- --with-mysql-dir=/usr/mysql"
    assure :gem, "mongrel", "1.1.5"
    assure :gem, "mongrel_cluster", "1.0.5"
    assure :gem, "fit", "1.1"
    assure :gem, "net-scp", "1.0.1"
    assure :gem, "libxml-ruby", "0.9.7"
    assure :gem, "rspec", "1.1.12"
    assure :gem, "rspec-rails", "1.1.12"
    assure :gem, "cucumber", "0.1.15"
  end
  
  def patch_inflector_rb
    patch = <<-PATCH
    275a276
    >     rescue Iconv::InvalidEncoding
    PATCH
    gemdir = capture("gem env gemdir").strip
    pf_put(patch, "patch.txt")
    invoke_command("sudo patch -i patch.txt #{gemdir}/gems/activesupport-2.2.2/lib/active_support/inflector.rb")
    invoke_command("rm patch.txt")
  end
end
