require 'rspec'

RSpec.configure do |config|
  config.color = true

  config.tty = true

  config.formatter = :documentation
  config.mock_with :mocha
end
