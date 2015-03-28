require 'active_record'
require 'logger'
require 'mysql2'
require 'yaml'

ActiveRecord::Base.establish_connection YAML::load_file(File.join(__dir__, '../config/database.yml'))['development']
I18n.enforce_available_locales = false

class DatabaseOperator
end

class BitvacuumScan < ActiveRecord::Base

end

class BitvacuumRun < ActiveRecord::Base

end
