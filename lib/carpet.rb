# extensions
require 'capistrano/deploy/remote_dependency'

# plugins
require 'plugins/src'
require 'plugins/pkg'
require 'plugins/zone'
require 'plugins/zfs'
require 'plugins/svc'
require 'plugins/adm'
require 'plugins/nfs'
require 'plugins/cpan'

# infrastructure
require "infrastructure/zones"

# appliances
require "appliances/apache_lb"
require "appliances/rails22"
require "appliances/mysql"
require "appliances/memcached"

# Temporarily sets an environment variable, yields to a block, and restores
# the value when it is done.
def with_env(name, value)
  saved, ENV[name] = ENV[name], value
  yield
ensure
  ENV[name] = saved
end

def assure(type, *args, &block)
  dependency = Capistrano::Deploy::RemoteDependency.new(self).send(type, *args)
  unless dependency.pass?
    if block 
      yield
    else
      abort "#{type} dependency with #{args.inspect} not met and no block given to resolve it!"
    end
  end
  dependency.send("after_#{type}") if dependency.respond_to?("after_#{type}")
end

def node(name, type, params={})
  node = params[:ipaddress].to_a[0] || name
  set(:nfs_server, node) if params[:nfs_server]
  if node != name
    params[:name] = name
  end
  hosted_on = params[:hosted_on]
  server(node, type, params)
  task(name, :roles => type) do
    unless hosted_on.nil?
      need_host_for_node(node, hosted_on)
      assure_zone_on_host(name, hosted_on, params)
    end
    need_type(node, type)
  end
end

def need_host_for_node(node, hosted_on)
  with_env("HOSTS", node) do
    needs hosted_on
  end
end

def assure_zone_on_host(name, hosted_on, params)
  hosted_on_ip = find_servers(:only => {:name => hosted_on})[0].host
  with_env("HOSTS", hosted_on_ip) do
    set(:zone_name, name)
    set(:zone_options, params)
    needs :a_zone
    unset(:zone_name)
    unset(:zone_options)
  end
end

def need_type(node, type)
  with_env("HOSTS", node) do
    needs type
  end
end

def type(name, *args, &block)
  task(name, :roles => name, *args, &block)
end

def needs(name, *args)
  find_and_execute_task(name)
end

def render(path, vars={})
  b = binding
  vars.each { |key, value| eval("#{key} = vars[:#{key}] || vars['#{key}']", b) }
  ERB.new(File.read(path)).result(b)
end

def find_param_by_node_name(param, node)
  find_param(param, :only => { :name => node})
end

def find_param(param, query)
  result = nil
  with_env('HOSTS', nil) do
    servers = find_servers(query)
    if servers.length == 1
      server = servers[0]
      result = server.options[param] unless server.nil?
    end
  end
  result
end

def find_node_by_param(param, value)
  result = nil
  with_env('HOSTS', nil) do
    servers = find_servers(:only => {param => value})
    result = servers.first unless servers.nil?
  end
  result
end

def find_node_by_ipaddress(ipaddress)
  result = nil
  with_env('HOSTS', nil) do
    servers = find_servers()
    result = servers.select { |server| server.options[:ipaddress].to_a.include?(ipaddress) }.first
  end
  result
end

def current_host
  current_node.host
end

def current_node
  result = nil
  ipaddress = ENV['HOSTS']
  with_env('HOSTS', nil) do
    result = find_node_by_ipaddress(ipaddress)
  end
  result
end

def rake(task, options={})
  rake = fetch(:rake, "rake")
  invoke_command("cd #{current_path}; #{rake} RAILS_ENV=#{deploy_env} #{task}", options)
end

def schedule_rake_task(task, params={})
  "#{params[:minute] || "*"} #{params[:hour] || "*"} #{params[:day_of_month] || "*"} #{params[:month] || "*"} #{params[:day_of_week] || "*"} /usr/local/bin/ruby /usr/local/bin/rake RAILS_ENV=#{deploy_env} --trace --rakefile #{current_path}/Rakefile --libdir=#{current_path} #{task} >> #{shared_path}/log/crontab.log 2>&1\n"
end

# TODO: SOLARIS specific stuff should go somewhere else
def pfexec(cmd, options={}, &block)
  p_cmd = "pfexec #{cmd}"
  if options.has_key?(:via)
    send(options[:via], p_cmd, options, &block)
  else
    run_opts = options.dup
    run_opts.delete(:via)
    run(p_cmd, run_opts.merge(:shell => "pfsh"), &block)
  end
end

def zlogin(cmd, options={}, &block)
  z_cmd = "/usr/sbin/zlogin #{options[:zone]} '#{cmd}'"
  run_opts = options.dup
  run_opts.delete(:via)
  run(z_cmd, run_opts.merge(:shell => "pfsh"), &block)
end

def pf_put(data, path, options={})
  opts = options.dup
  tmp = opts.delete(:tmp) || "/tmp"
  owner = opts.delete(:owner)
  group = opts.delete(:group)
  mode = opts.delete(:mode) # avoid Capistrano::Configuration::Actions::FileTransfer.upload to try to set the mode using :run (instead of invoke_command)
  file = path.split("/").last
  put_opts = opts.dup
  put_opts.delete(:via)
  path = "/zones/#{options[:zone]}/root#{path}" if opts[:via] == :zlogin && !opts[:zone].nil?
  put(data, "#{tmp}/#{file}", put_opts)
  pfexec("mv #{tmp}/#{file} #{path}", put_opts)
  adm.chown(path, put_opts.merge(:owner => owner)) if owner
  adm.chgrp(path, put_opts.merge(:group => group)) if group
  adm.chmod(path, put_opts.merge(:mode => mode)) if mode
end
