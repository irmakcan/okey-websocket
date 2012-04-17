require 'bundler'
#Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

namespace :daemon do
  task :run do
    system("bundle exec ruby bin/daemon.rb run")
  end
  task :start do
    system("bundle exec ruby bin/daemon.rb start")
    puts "Server successfully started"
  end
  task :stop do
    system("bundle exec ruby bin/daemon.rb stop")
  end
end

task :sync do
  system("rsync -rav -e ssh ../okey-websocket/ irmak@www.okey.irmakcan.com:/home/irmak/projects/okey-websocket")
end