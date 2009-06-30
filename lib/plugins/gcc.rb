module Gcc
  def install!()
    pkg.install("SUNWgcc")
    # remove the soft link that shadows SunStudio's cc
    pfexec('rm /usr/gnu/bin/cc')
  end
end

Capistrano.plugin :gcc, Gcc