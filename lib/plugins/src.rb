require 'capistrano'

module Src
  def install(url, options={})
    assure :command, "cc" do
      pkg.install("SUNWfontconfig")
      # TODO: change to "sunstudio12u1" when upgrading to OpenSolaris 2009.06 (_if_ Sun CC is still required)
      # see: http://developers.sun.com/sunstudio/downloads/opensolaris/index.jsp
      pkg.install("sunstudioexpress@0.2008.11,5.11-0.86:20081113T205836Z")
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