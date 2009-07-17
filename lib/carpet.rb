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
require 'plugins/nagios'
require 'plugins/gcc'

# infrastructure
require "infrastructure/zones"

# appliances
require "appliances/apache_lb"
require "appliances/haproxy"
require "appliances/mongrel_cluster"
require "appliances/passenger_nginx_server"
require "appliances/nginx"
require "appliances/thin"
require "appliances/mysql"
require "appliances/memcache"

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
    assure_nagios_scripts_on_host(hosted_on)
    assure_nagios_scripts_on_node(params[:ipaddress].to_a[0]) if params[:nagios_services]
    add_services_to_nagios_server(name, params[:ipaddress].to_a[0], type, params[:nagios_services]) if params[:nagios_services]
  end
end

def get_attribute(name, default_value)
  current_node.options[name.to_sym] || fetch(name.to_sym, default_value)
end

def add_services_to_nagios_server(node_name, ipaddress, type, nagios_services)
  roles[type].servers.each do |server|
    nagios.add_host(server.options[:name], server.options[:ipaddress])
  end
  nagios.add_hostgroup(type, roles[type].servers.collect {|server| server.options[:name]}.join(","))
  nagios_services.each do |service, service_details|
    nagios.add_service(service, node_name, service_details)
  end
  nagios.restart!
end

def assure_nagios_scripts_on_node(ipaddress)
  with_env("HOSTS", ipaddress) do
    assure(:match, "/usr/local/nagios/libexec/check_users -w 100 -c 100", /OK/) do
      nagios.install_plugins()
    end
    assure(:file, "/usr/local/nagios/libexec/check_cpu_stats.sh", File.read("#{File.dirname(__FILE__)}/../resources/nagios-plugins/check_cpu_stats.sh"), :mode => 755)
    assure(:file, "/usr/local/nagios/libexec/check_smf.sh", File.read("#{File.dirname(__FILE__)}/../resources/nagios-plugins/check_smf.sh"), :mode => 755)
    assure(:file, "/usr/local/nagios/libexec/check_proc_mem.sh", File.read("#{File.dirname(__FILE__)}/../resources/nagios-plugins/check_proc_mem.sh"), :mode => 755)
  end
end

def assure_nagios_scripts_on_host(host)
  with_env("HOSTS", find_param_by_node_name(:ipaddress, host)) do
    assure(:file, "/usr/local/nagios/libexec/check_zone_cpu.sh", File.read("#{File.dirname(__FILE__)}/../resources/nagios-plugins/check_zone_cpu.sh"), :mode => 755)
    assure(:file, "/usr/local/nagios/libexec/check_zone_mem.sh", File.read("#{File.dirname(__FILE__)}/../resources/nagios-plugins/check_zone_mem.sh"), :mode => 755)
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
  path = "#{File.dirname(__FILE__)}/../resources/#{path}" if not File.exists?(path)
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
  invoke_command(build_rake_command(task), options)
end

def build_rake_command(task)
  rake = fetch(:rake, "rake")
  "cd #{current_path}; #{rake} RAILS_ENV=#{deploy_env} #{task}"
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
