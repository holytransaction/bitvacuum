require 'singleton'

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
      value = inputs.map { |i| i['amount'] }.reduce :+
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
    @currencies = operator.configuration.param['currencies']
    unless @currencies.include? currency_name or currency_name == 'all'
      raise "Unknown currency #{currency_name}"
    end
    if currency_name == 'all'
      @currencies.each do |currency|
        @operational_currencies.push({name: currency, config: wallets[currency]})
      end
    else
      @operational_currencies.push({name: currency_name, config: wallets[currency_name]})
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
    unspent = @connection.listunspent.select { |t| t['amount'] <= threshold }
    unspent.sort_by { |t| t['amount'] }
  end

  def accumulate_inputs(inputs)
    buffer = []
    while calculate_transaction_size(buffer) <= operator.configuration.param['transaction_size'] &&
        calculate_value_of_inputs(buffer) <= operator.configuration.param['minimum_transaction_value'] ||
        calculate_transaction_size(buffer) > operator.configuration.param['transaction_size'] do

      if inputs.empty?
        puts 'No more inputs to process, transaction value is still not optimal'
        break
      end

      buffer = buffer.push(inputs.slice!(-1))
      if calculate_transaction_size(buffer) > operator.configuration.param['transaction_size']

        if inputs.count < 2
          puts 'Inputs count is less than 2'
          break
        end

        puts 'Warning: Transaction size limit is exceeded, trying to change last two inputs to more valuable one !'
        inputs = inputs.push(buffer.slice!(-1, 2)).flatten
        buffer = buffer.slice!(-1, 2)
        buffer = buffer.push(inputs.slice!(0))
      end

      # puts "Now transaction buffer is: #{buffer}"
      printf 'Transaction buffer value is: %f; ', calculate_value_of_inputs(buffer)
      puts "Transaction buffer size is: #{calculate_transaction_size(buffer)}"
    end
    buffer
  end
end
