require 'lib/carpet'

# FIRST, specify the types of servers you want. Usually you define one type
# for every role you would define in Capistrano. 
# Here you will define, what all servers of that type should have installed - 
# usually you want to use a pre-defined appliance (like apache_lb) plus some
# self-defined tasks (like our :print_uname here)
type :web do
  needs :print_uname
end

# SECOND, specify the server instances (or nodes) you want to install/maintain
# node <hostname>, <type, as defined above>, <params like ipaddress, etc>
node 'localhost', :web, {
  :ipaddress => "127.0.0.1"
}

# THIRD, d
# Any capistrano tasks may be used by types or other tasks using :needs :my_task
task :print_uname do
  puts `uname -a`
end
