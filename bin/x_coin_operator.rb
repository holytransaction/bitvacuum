require 'singleton'
require 'bitcoin'
require_relative 'configuration'
require 'awesome_print'

class XCoinOperator
  include Singleton

  def calculate_transaction_size(inputs)
    if inputs.empty?
      0
    else
      inputs.count * 180 + 34 + inputs.count
    end
  end

  def configuration
    Configuration.instance
  end

  def calculate_value_of_inputs(inputs)
    if inputs.empty?
      0
    else
      if inputs.count == 1
        value = inputs.first['amount']
      else
        value = inputs.map { |i| i['amount'] }.reduce :+
      end
      value
    end
  end

  def operational_currencies
    @operational_currencies
  end

  def load_currency_configuration(currency_name)
    currency_name = currency_name.downcase
    @operational_currencies = []
    wallets = configuration.wallets
    @currencies = configuration.param['currencies']
    unless @currencies.include? currency_name or currency_name == 'all'
      raise "Unknown currency #{currency_name}"
    end
    if currency_name == 'all'
      @currencies.each do |currency|
        @operational_currencies.push({name: currency, config: wallets[currency]})
      end
    else
      @operational_currencies.push({ name: currency_name, config: wallets[currency_name] })
    end
  end

  def establish_connection(currency)
    @connection = Bitcoin::Client.new(currency[:config]['rpc_username'], currency[:config]['rpc_password'],
                                      :host => currency[:config]['rpc_host'], :port => currency[:config]['rpc_port'])
  end

  def scan_for_unspent_transactions(threshold)
    if threshold
      threshold = threshold.to_f
    else
      threshold = configuration.param['input_value_threshold']
    end
    unspent = @connection.listunspent
    filter_unspent_transactions(unspent,threshold)
  end

  def filter_unspent_transactions(inputs, threshold)
    inputs.select { |t| t['amount'] <= threshold }.sort_by! { |t| t['amount'] }
  end

  def accumulate_inputs(inputs)
    buffer = []
    while calculate_transaction_size(buffer) <= configuration.param['transaction_size'] &&
        calculate_value_of_inputs(buffer) <= configuration.param['minimum_transaction_value'] ||
        calculate_transaction_size(buffer) > configuration.param['transaction_size'] do

      if inputs.empty?
        puts 'No more inputs to process, transaction value is still not optimal'
        return []
      end
      buffer.sort_by! { |t| t['amount'] }
      inputs.sort_by! { |t| t['amount'] }
      if calculate_transaction_size(buffer) > configuration.param['transaction_size']

        if inputs.count < 2
          puts 'Inputs count is less than 2'
          return []
        end

        puts 'Warning: Transaction size limit is exceeded, trying to change two lesser inputs to more valuable one!'
        buffer = buffer.drop(2)
        buffer.push(inputs.pop)
      else
        buffer.push(inputs.take(1).first)
      end
      # puts "Now transaction buffer is: #{buffer}"
      printf 'Transaction buffer value is: %f; ', calculate_value_of_inputs(buffer)
      puts "Transaction buffer size is: #{calculate_transaction_size(buffer)}"
    end
    puts "Optimal transaction is accumulated. Total number of inputs: #{buffer.count}. Returning inputs buffer"
    buffer
  end
end
