Capistrano::Configuration.instance(:must_exist).load do 
  task :rails do
    assure :command, :ruby do
      src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz")
    end
    assure :command, :gem do
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
    
    assure :match, "gem list", "libxml"  do
      url = "http://rubyforge.org/frs/download.php/48087/libxml-ruby-0.9.6.tgz"
      tar_gz = url.split('/').last
      dir = tar_gz.gsub(".tgz", "") if tar_gz.include?(".tgz")
      invoke_command("test -f #{tar_gz} || wget --progress=dot:mega -N #{url}")
      invoke_command("/usr/gnu/bin/tar xzf #{tar_gz}")
      assure :file, "libxml-ruby-0.9.6/ext/libxml/sax_parser_callbacks.inc", File.read(File.dirname(__FILE__) + "/sax_parser_callbacks.inc")
      invoke_command("cd libxml-ruby-0.9.6 && pfexec rake && cd admin/pkg && pfexec gem install libxml-ruby --no-ri --no-rdoc")
    end
  end
end