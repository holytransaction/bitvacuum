require 'yaml'
require 'singleton'

class Configuration
  include Singleton

  def initialize
    @wallets_configuration = YAML::load_file(File.join(__dir__, '../config/wallets.yml'))
    @configuration = YAML::load_file(File.join(__dir__, '../config/application.yml'))
  end

  def param
    return @configuration
  end

  def wallets
    return @wallets_configuration
  end
end
