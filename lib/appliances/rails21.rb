Capistrano::Configuration.instance(:must_exist).load do 
  task :rails do
    assure :command, :ruby do
      src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p287.tar.gz", :configure_opts => "--without-gcc")
    end
    assure :match, "gem --version", "1.3.1" do
      src.install("http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz", :install_cmd => "pfexec ruby ./setup.rb")
    end
    assure :package, "SUNWlxml"
    assure :package, "SUNWgnu-libiconv"
    adm.ln("/usr/gnu/lib/libiconv.so.2", "/usr/lib/libiconv.so.2") # needed as /usr/gnu/lib is not in libary load path
    assure :package, "SUNWzlib"
    assure :package, "SUNWimagick"
    assure :package, "SUNWmysql5"
    assure :package, "SUNWsvn"
    
    assure :gem, "hoe", "1.8.2"
    assure :gem, "mini_magick", "1.2.3"
    assure :gem, "rubyzip", "0.9.1"
    assure :gem, "rails", "2.1.0"
    assure :gem, "memcache-client", "1.5.0"
    assure :gem, "fastercsv", "1.4.0"
    assure :gem, "mysql", "2.7", :gem_opts => "-- --with-mysql-dir=/usr/mysql"
    assure :gem, "mongrel", "1.1.5"
    assure :gem, "mongrel_cluster", "1.0.5"
    assure :gem, "fit", "1.1"
    assure :gem, "net-scp", "1.0.1"
    assure :gem, "libxml-ruby", "0.9.7"
  end
end