#!/usr/bin/env ruby
require 'gli'
require 'yaml'
require_relative 'x_coin_operator'
require 'awesome_print'
require 'airbrake'

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

    ap "Running scan with options: #{options}"
    puts '====='

    operator.operational_currencies.each do |currency|
      puts "Scanning for unspent transactions for currency: #{currency[:name]}"
      operator.establish_connection(currency)
      unspent = operator.scan_for_unspent_transactions(options[:threshold])
      puts "Found #{unspent.count} unspent transactions."
      ap unspent
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

  c.desc 'Transaction fee to pay per 1000 bytes'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['fee'] # TODO: To investigate why configuration method cannot be invoked here
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

  c.desc 'Minimum transaction value'
  c.default_value YAML::load_file(File.join(__dir__, '../config/application.yml'))['minimum_transaction_value'] # TODO: To investigate why configuration method cannot be invoked here
  c.arg_name '[VALUE]'
  c.flag [:m, :min_transaction_value]

  c.action do |global_options, options, args|
    if options[:threshold]
      threshold = options[:threshold].to_f
    else
      threshold = operator.configuration.param['input_value_threshold'].to_f
    end
    if options[:transactions_to_send]
      operator.configuration.param['transactions_to_send'] = options[:transactions_to_send].to_i
    end
    if options[:fee]
      operator.configuration.param['fee'] = options[:fee].to_f
    end
    if options[:size]
      operator.configuration.param['transaction_size'] = options[:size].to_i
    end
    if options[:inputs]
      operator.configuration.param['inputs_to_start'] = options[:inputs].to_i
    end
    if options[:min_transaction_value]
      operator.configuration.param['minimum_transaction_value'] = options[:min_transaction_value].to_f
    end

    ap "Running 'run' with options: #{options}"
    puts '====='

    operator.run_accumulation(threshold)
  end
end

pre do |global, command, options, args|
  Airbrake.configure do |config|
    config.api_key = operator.configuration.param['airbrake_key']
  end
  @options = options
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
  env_hash = ENV.to_hash
  env_hash[:command_line_arguments] = @options
  Airbrake.notify_or_ignore(exception, error_message: "[BitVacuum]: #{exception.message}", cgi_data: env_hash)
end

def operator
  XCoinOperator.instance
end

exit run(ARGV)

