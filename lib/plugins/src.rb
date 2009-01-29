require 'capistrano'

module Src
  def install(url, options={})
    assure :command, "cc" do
      pkg.install("SUNWfontconfig")
      pkg.install("sunstudioexpress")
    end
    configure_opts = options.delete(:configure_opts)
    tar_gz = url.split('/').last
    dir = tar_gz.gsub(".tar.gz", "") if tar_gz.include?(".tar.gz")
    dir = tar_gz.gsub(".tgz", "") if tar_gz.include?(".tgz")
    dir.gsub!("_", "-")
    invoke_command("test -f #{tar_gz} || wget --progress=dot:mega -N #{url}", options)
    invoke_command("/usr/gnu/bin/tar xzf #{tar_gz}", options)
    install_cmd = "cd #{dir} && #{options.delete(:install_cmd) || "CC=cc ./configure#{' '+configure_opts unless configure_opts.nil?} && gmake && pfexec gmake install"}"
    invoke_command(install_cmd, options)
    pfexec("rm #{tar_gz}")
    pfexec("rm -rf #{dir}")
  end
end

Capistrano.plugin :src, Src