require 'active_record'
require 'logger'
require 'mysql2'
require 'yaml'

config_file = YAML::load_file(File.join(__dir__, '../config/database.yml'))
unless ENV['RACK_ENV'] == 'test'
  ActiveRecord::Base.establish_connection config_file['development']
else
  ActiveRecord::Base.establish_connection config_file['test']
end

I18n.enforce_available_locales = false

class DatabaseOperator
end

class BitvacuumScan < ActiveRecord::Base

end

class BitvacuumRun < ActiveRecord::Base

end
