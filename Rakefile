require 'bundler'
#Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

namespace :thin do
  task :run do
    system("thin start -R bin/daemon.rb")
  end
  task :start do
    system("thin start -d -R bin/daemon.rb")
    puts "Server successfully started"
  end
  task :stop do
    puts "Stopping Okey Server"
    system("thin stop")
  end
  task :restart do
    Rake::Task["thin:stop"].invoke
    Rake::Task["thin:start"].invoke
  end
end

task :sync do
  system("rsync -rav -e ssh --exclude-from .gitignore ../okey-websocket/ irmak@www.okey.irmakcan.com:/home/irmak/projects/okey-websocket")
end

