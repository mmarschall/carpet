require 'capistrano'

module Cpan
  
  def install(mod, options={})
    assure :command, "cc" do
      pkg.install("SUNWfontconfig")
      pkg.install("sunstudioexpress")
    end
    assure(:directory, "/export/home/#{application_user}/.cpan/CPAN", options)
    assure(:file, "/export/home/#{application_user}/.cpan/CPAN/MyConfig.pm", File.read("#{File.dirname(__FILE__)}/../../resources/Config.pm"), options)
    pfexec("/usr/perl5/bin/cpan install #{mod}", options)
  end
end

Capistrano.plugin :cpan, Cpan