require 'Open3'
require 'yaml'

class Daemon
  loop do
    system('cd ' +File.expand_path('..',  __FILE__) + ';bundle exec bin/bitvacuum.rb ' + ARGV.join(" "))
    sleep(YAML::load_file(File.join(__dir__, 'daemon.yml'))['operation_interval'] * 60)
  end
end
