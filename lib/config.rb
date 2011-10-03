require 'yaml'

# Defaults
CONFIG = {
  :authenticate     => true,
  :app_port         => '3000',
  :web_socket_port  => '3001',
  :redis_host       => 'localhost',
  :redis_port       => '6379',
  :daemonize        => false,
  :log_file         => 'bulb.log',
  :pid_file         => 'bulb.pid'
}

path = File.expand_path('../../config.yml', __FILE__)
if File.exists?(path)
  config = YAML.load_file(path).inject({}) do |memo, (key, value)|
    memo[key.to_sym] = value
    memo
  end

  CONFIG.update(config)
end
