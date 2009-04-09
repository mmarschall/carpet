Capistrano::Configuration.instance(:must_exist).load do 
  task :rails22 do
    rails_default_permissions = {:owner => application_user, :group => "staff", :mode => 775}
    assure :directory, "#{shared_path}", {:owner => application_user, :group => "staff", :mode => 755}
    assure :directory, "#{shared_path}/log", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config/environments", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/tmp", fetch(:default_permissions, rails_default_permissions)
    assure :match, "ruby --version", /1.8.7/ do
      pkg.set_authority("pending", "http://pkg.opensolaris.org/pending/") unless pkg.authority?("pending")
      assure :package, "readline5"
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
    assure :gem, "rack", "0.9.1"
    assure :gem, "rails", "2.3.2"
    assure :gem, "memcache-client", "1.5.0"
    assure :gem, "fastercsv", "1.4.0"
    assure :gem, "mysql", "2.7", :gem_opts => "-- --with-mysql-dir=/usr/mysql"
    assure :gem, "mongrel", "1.1.5"
    assure :gem, "mongrel_cluster", "1.0.5"
    assure :gem, "fit", "1.1"
    assure :gem, "net-scp", "1.0.1"
    assure :gem, "libxml-ruby", "0.9.7"
    assure :gem, "rspec", "1.2.2"
    assure :gem, "rspec-rails", "1.2.2"
    assure :gem, "cucumber", "0.1.15"
  end
end
