require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |task|
  task.libs << 'test'
  task.test_files = FileList['test/*_test.rb']
  task.verbose = true
end

task :deploy do
  url = ENV['URL'] or raise 'Give me url to deploy to (URL=ssh://foo.bar/baz)'
  url = url + '/' unless url[-1] == '/'

  files = ['bin', 'config.rb', 'lib', 'public', 'views']
  files.each do |file|
    command = "scp -r #{file} #{url}#{file}"
    puts command
    `#{command}`
  end
end
