require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |task|
  task.libs << '.'
  task.test_files = FileList['test/*_test.rb']
  task.verbose = true
end
