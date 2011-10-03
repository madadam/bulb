require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |task|
  task.libs << 'test'
  task.test_files = FileList['test/*_test.rb']
  task.verbose = true
end

desc 'Deploy the app to the server'
task :deploy do
  server  = ENV['BULB_DEPLOY_SERVER'] or abort('Missing env variable BULB_DEPLOY_SERVER')
  dir     = ENV['BULB_DEPLOY_DIR'] || '~/bulb'

  # Hack, to make sure rvm is available in non-interactive ssh shells.
  rvm = 'source ~/.rvm/scripts/rvm'

  puts color('0;32', "Deploying to #{color('1;32', "#{server}:#{dir}")} ...")

  ssh server, "mkdir -p #{dir}"
  ssh server, "#{rvm} && cd #{dir} && bin/server stop", false
  ssh server, "cd #{dir} && rm -rf *"

  files = %w[bin Gemfile Gemfile.lock lib public views]
  run "tar -czO #{files.join(' ')} | ssh #{server} \"cd #{dir} && tar -xz\""

  config = ''
  config << "daemonize: true\n"
  config << "password:  #{ENV['BULB_DEPLOY_PASSWORD']}\n" if ENV['BULB_DEPLOY_PASSWORD']

  ssh server, "cd #{dir} && echo \"#{config}\" > config.yml"

  ssh server, "#{rvm} && cd #{dir} && bundle install --without development test"
  ssh server, "#{rvm} && cd #{dir} && bin/server start"

  puts color('0;32', 'Done')
end

def run(command, abort_on_fail = true)
  puts ">> #{color('0;35', command)}"
  system command or (abort_on_fail and abort)
end

def ssh(server, command, abort_on_fail = true)
  command = command.gsub('"', '\"')
  run "ssh #{server} \"#{command}\"", abort_on_fail
end

def color(code, text)
  "\e[#{code}m#{text}\e[0m"
end
