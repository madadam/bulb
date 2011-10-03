# Defaults
CONFIG = {
  :app_port         => '3000',
  :web_socket_port  => '3001',
  :redis_host       => 'localhost',
  :redis_port       => '6379',
  :daemonize        => false,
  :log_file         => 'bulb.log',
  :pid_file         => 'bulb.pid'
}

path = File.expand_path('../../config.rb', __FILE__)
require path if File.exists? path
