require 'singleton'
require 'bitcoin'
require_relative 'configuration'
require 'awesome_print'
require_relative 'database_operator'

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
    if @connection.nil?
      @operational_currency_name = currency[:name]
      @connection = Bitcoin::Client.new(currency[:config]['rpc_username'], currency[:config]['rpc_password'],
                                        :host => currency[:config]['rpc_host'], :port => currency[:config]['rpc_port'])
    else
      @connection
    end
  end

  def scan_for_unspent_transactions(threshold)
    if threshold
      threshold = threshold.to_f
    else
      threshold = configuration.param['input_value_threshold']
    end
    unspent = @connection.listunspent
    filtered = filter_unspent_transactions(unspent,threshold)
    BitvacuumScan.create(number_of_inputs: filtered.count, total_amount: calculate_value_of_inputs(filtered),
                         currency: @operational_currency_name).save
    filtered
  end

  def lock_inputs(inputs)
    puts 'Locking unspent inputs to prevent Automatic Coin Selector to collect them'
    @connection.lockunspent(inputs)
  end

  def unlock_inputs(inputs)
    @connection.unlockunspent(inputs)
  end

  def create_raw_transaction(inputs, address, amount)
    transaction_buffer = []
    inputs.each do |input|
      transaction_buffer << { :txid => input['txid'], :vout => input['vout']}
    end
    @connection.createrawtransaction(transaction_buffer, { "#{address}" => amount })
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
          puts "Remaining inputs for operation count is less than 2. Inputs count: #{inputs.count}"
          return []
        end

        puts 'Warning: Transaction size limit is exceeded, trying to change two lesser inputs to more valuable one!'
        buffer = buffer.drop(2)
        buffer.push(inputs.pop)
      else
        input_to_push = inputs.take(1).first
        inputs = inputs.drop(1)
        buffer.push(input_to_push)

      end
      printf 'Transaction buffer value is: %f; ', calculate_value_of_inputs(buffer)
      puts "Transaction buffer size is: #{calculate_transaction_size(buffer)}"
    end
    puts "Optimal transaction is accumulated. Total number of inputs: #{buffer.count}. Returning inputs buffer"
    buffer
  end

  def get_list_of_locked_inputs
    @connection.listlockunspent
  end

  def get_new_address
    @connection.getnewaddress
  end

  def inputs_are_locked?(inputs, locked_list)
    if inputs & locked_list
      true
    else
      false
    end
  end

  def run_accumulation(threshold)
    operator.operational_currencies.each do |currency|
      puts "Scanning for unspent transactions for currency: #{currency[:name]}"
      establish_connection(currency)
      unspent = scan_for_unspent_transactions(threshold)
      if unspent.count < configuration.param['inputs_to_start']
        puts 'Not enough inputs to start cleaning'
        return false
      end
      puts "Found #{unspent.count} unspent inputs."
      operational_inputs = []
      transaction_buffer = []
      configuration.param['transactions_to_send'].times do
        operational_inputs = scan_for_unspent_transactions(threshold)
        unless operational_inputs.nil?
          transaction_buffer = accumulate_inputs(operational_inputs)
          if transaction_buffer.count > 1
            lock_inputs(transaction_buffer)
            address = get_new_address
            raw_transaction = create_raw_transaction(transaction_buffer, address,
                                                     calculate_value_of_inputs(transaction_buffer))
            ap "Raw transaction is: #{raw_transaction}"
            signed_raw_transaction = sign_raw_transaction(raw_transaction)
            ap "Signed transaction is: #{raw_transaction}"
            if signed_raw_transaction['complete']
              puts 'Transaction has been signed successfully'
              sent_raw_transaction = send_raw_transaction(signed_raw_transaction['hex'])
              ap "Sent transaction TXID: #{sent_raw_transaction}"
              BitvacuumRun.create(number_of_inputs: transaction_buffer.count,
                                   total_amount: calculate_value_of_inputs(transaction_buffer),
                                   address: address, sent_transaction_id: sent_raw_transaction,
                                   currency: currency[:name]).save
              unlock_inputs(transaction_buffer)
            else
              unlock_inputs(transaction_buffer)
              puts 'Warning: One or several inputs became unspendable, rerunning last iteration...'
              redo
            end
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

  def sign_raw_transaction(raw_transaction)
    @connection.signrawtransaction(raw_transaction)
  end

  def send_raw_transaction(signed_transaction_hex)
    @connection.sendrawtransaction(signed_transaction_hex)
  end
end
