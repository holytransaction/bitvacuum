#!/usr/bin/env ruby
require 'gli'
require 'yaml'
require 'bitcoin'
require_relative 'x_coin_operator'
require_relative 'configuration'

include GLI::App

program_desc 'BitVacuum is an application that is intended to clean dust (small transactions) out of the XCOIN wallets'

subcommand_option_handling :normal
arguments :strict

desc 'Scans for unspent transactions in selected wallet(s) below the threshold'
arg_name '| Example of usage: bitvacuum scan -c BitCoin -t 0.0001'
command :scan do |c|
  c.desc 'Verbose. #Currently not implemented'
  c.switch [:v, :verbose]

  c.desc 'Specify currency (Bitcoin, Litecoin, Dogecoin, Darkcoin etc)'
  c.default_value 'all'
  c.arg_name '[CURRENCY NAME]'
  c.flag [:c, :currency]

  c.desc 'Maximum input amount'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['input_value_threshold'] # TODO: To investigate why configuration method cannot be invoked here
  c.arg_name '[VALUE]'
  c.flag [:t, :threshold]

  c.action do |global_options, options, args|

    puts "Running scan with options: #{options}"
    puts '====='

    operator.operational_currencies.each do |currency|
      puts "Scanning for unspent transactions for currency: #{currency[:name]}"
      operator.establish_connection(currency)
      unspent = operator.scan_for_unspent_transactions(options[:threshold])
      # TODO: To store results in database. # of inputs, date total amount. Create new table table bitvacuum_run in cryptoserver DB (test and dev)
      puts "Found #{unspent.count} unspent transactions."
      puts unspent
      puts 'Scan successful!'
    end

  end
end

desc 'Merge small inputs into bigger transactions'
command :run do |c|
  c.desc 'Specify currency (Bitcoin, Litecoin, Dogecoin, Darkcoin etc)'
  c.default_value 'all'
  c.arg_name '[CURRENCY NAME]'
  c.flag [:c, :currency]

  c.desc 'Maximum input amount'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['input_value_threshold'] # TODO: To investigate why configuration method cannot be invoked here
  c.arg_name '[VALUE]'
  c.flag [:t, :threshold]

  c.desc 'Number of transactions to send'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['transactions_to_send'] # TODO: To investigate why configuration method cannot be invoked here
  c.arg_name '[VALUE]'
  c.flag [:n, :transactions_to_send]

  c.desc 'Maximum transaction fee'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['transaction_fee'] # TODO: To investigate why configuration method cannot be invoked here
  c.arg_name '[VALUE]'
  c.flag [:f, :fee]

  c.desc 'Maximum transaction size in bytes'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['transaction_size'] # TODO: To investigate why configuration method cannot be invoked here
  c.arg_name '[VALUE]'
  c.flag [:s, :size]

  c.desc 'Minimum inputs to start cleaning'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['inputs_to_start'] # TODO: To investigate why configuration method cannot be invoked here
  c.arg_name '[VALUE]'
  c.flag [:i, :inputs]

  c.action do |global_options, options, args|
    if options[:threshold]
      threshold = options[:threshold].to_f
    else
      threshold = config['input_value_threshold']
    end

    puts "Running scan with options: #{options}"
    puts '====='

    operator.operational_currencies.each do |currency|
      puts "Scanning for unspent transactions for currency: #{currency[:name]}"
      operator.establish_connection(currency)
      unspent = operator.scan_for_unspent_transactions(threshold)
      puts "Found #{unspent.count} unspent inputs."
      operational_inputs = unspent
      transaction_buffer = []
      operator.configuration.param['transactions_to_send'].times do
        unless operational_inputs.nil?
          transaction_buffer = operator.accumulate_inputs(operational_inputs)
          if transaction_buffer.count > 1 &&
              operator.calculate_transaction_size(transaction_buffer) <= operator.configuration.param['transaction_size'] &&
              operator.calculate_value_of_inputs(transaction_buffer) >= operator.configuration.param['minimum_transaction_value']

            puts 'Create, sign and send transaction' # TODO: Lock inputs. Create, sign and send transaction
            # TODO: To store results in database. # of inputs, total, date, address (refer to cryptoserver) Create new table table bitvacuum_run in cryptoserver DB (test and dev)
          else
            puts 'No fulfilling transactions created'
            break
          end
        else
          puts 'Nothing to clean!'
          break
        end
      end

    end
  end
end

pre do |global, command, options, args|
  operator.load_currency_configuration options[:currency]
  true
end

post do |global, command, options, args|
  # Post logic here
  # Use skips_post before a command to skip this
  # block on that command only
end

on_error do |exception|
  puts "Error occured: #{exception.message}"
end

def operator
  XCoinOperator.instance
end

exit run(ARGV)

