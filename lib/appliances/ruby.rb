Capistrano::Configuration.instance(:must_exist).load do
  task :ruby do
    assure :match, "ruby --version", /ruby 1\.8\.7 \(2008-08-11 patchlevel 72\)/ do
      pkg.set_authority("pending", "http://pkg.opensolaris.org/pending/") unless pkg.authority?("pending")
      assure :package, "readline5"
      src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz", :configure_opts => "--without-gcc")
    end
  end
end
