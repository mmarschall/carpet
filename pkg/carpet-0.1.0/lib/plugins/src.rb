require 'capistrano'

module Src
  def install(url, options={})
    assure :command, "cc" do
      pkg.install("sunstudioexpress")
    end
    configure_opts = options.delete(:configure_opts)
    tar_gz = url.split('/').last
    dir = tar_gz.gsub(".tar.gz", "") if tar_gz.include?(".tar.gz")
    dir = tar_gz.gsub(".tgz", "") if tar_gz.include?(".tgz")
    invoke_command("test -f #{tar_gz} || wget --progress=dot:mega -N #{url}", options)
    invoke_command("/usr/gnu/bin/tar xzf #{tar_gz}", options)
    install_cmd = "cd #{dir} && #{options.delete(:install_cmd) || "./configure#{' '+configure_opts unless configure_opts.nil?} && make && pfexec make install"}"
    invoke_command(install_cmd, options)
  end
end

Capistrano.plugin :src, Src