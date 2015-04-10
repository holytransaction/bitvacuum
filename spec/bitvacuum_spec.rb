require_relative 'spec_helper'
require_relative '../bin/x_coin_operator'
require 'yaml'
require 'awesome_print'

describe 'BitVacuum' do
  it 'establishes connection with the first XCOIN RPC server from configuration' do
    XCoinOperator.instance.configuration.param['currencies'].first do |currency|
      currency_configuration = XCoinOperator.instance.load_currency_configuration(currency).pop
      expect(XCoinOperator.instance.establish_connection(currency_configuration).getinfo['testnet']).to be(false)
    end
  end

  it 'filters inputs with value below threshold' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_fulfil'], 0.01)
    unspent.each do |input|
      expect(input['amount']).to be <= 0.01
    end
  end
  it 'calculates transaction size' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_fulfil'], 0.01)
    size = XCoinOperator.instance.calculate_transaction_size(unspent)
    expect(size).to be(2206)
  end
  it 'calculates total amount of multiple inputs' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_not_fulfil'], 0.01)
    total_amount = XCoinOperator.instance.calculate_value_of_inputs(unspent)
    expect(total_amount).to be(0.0011200000000000001)
  end
  it 'accumulates dust inputs into valid free from fees transaction' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_fulfil'], 0.01)
    accumulated = XCoinOperator.instance.accumulate_inputs(unspent)
    expect(XCoinOperator.instance.calculate_transaction_size(accumulated)).
        to be(939)

    expect(XCoinOperator.instance.calculate_value_of_inputs(accumulated)).
        to be(0.01053021)
  end
  it 'returns empty array if cannot collect enough dust inputs into the fulfilling transaction' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_not_fulfil'], 0.01)
    accumulated = XCoinOperator.instance.accumulate_inputs(unspent)
    expect(accumulated.empty?).
        to be(true)
  end
  it 'can spot that there is no dust in the wallet' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_no_dust'], 0.01)
    expect(unspent.empty?).
        to be(true)
  end
  it 'can spot that accumulated dust inputs are not eligible for sending' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_fulfil'], 0.01)
    locked = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_locked'], 0.01)
    expect(XCoinOperator.instance.inputs_are_locked?(unspent,locked)).to be(true)
  end
  it 'validates inputs before sending to prevent double-spend' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_fulfil'], 0.01)
    stub_xcoin_operator(unspent)

    XCoinOperator.instance.stubs(:send_raw_transaction).returns('SENT_RAW_TRANSACTION_HASH_STUB')
    XCoinOperator.instance.stubs(:sign_raw_transaction).returns('complete' => false).then.returns('complete' => true)
    XCoinOperator.instance.expects(:unlock_inputs).twice.returns(true)
    XCoinOperator.instance.run_accumulation(0.01)
  end
  it 'sends transaction with accumulated inputs' do
    inputs = YAML::load(File.open(File.dirname(__FILE__) + '/fixtures/inputs.yml'))
    unspent = XCoinOperator.instance.filter_unspent_transactions(inputs['inputs_fulfil'], 0.01)
    stub_xcoin_operator(unspent)

    XCoinOperator.instance.stubs(:sign_raw_transaction).returns('complete' => true)
    XCoinOperator.instance.expects(:unlock_inputs).returns(true)
    XCoinOperator.instance.expects(:send_raw_transaction).returns('SENT_RAW_TRANSACTION_HASH_STUB')
    XCoinOperator.instance.run_accumulation(0.01)
  end
end

def stub_xcoin_operator(unspent)
  XCoinOperator.instance.stubs(:operator).returns(XCoinOperator.instance)
  XCoinOperator.instance.configuration.stubs(:param).returns({ 'transactions_to_send' => 1, 'inputs_to_start' => 10,
                                                               'transaction_size' => 1000,
                                                               'minimum_transaction_value' => 0.01})
  bitcoin_client = mock()
  XCoinOperator.instance.stubs(:establish_connection).returns(bitcoin_client)
  XCoinOperator.instance.stubs(:lock_inputs).returns(true)
  XCoinOperator.instance.stubs(:get_new_address).returns('NEW_ADDRESS_STUB')
  XCoinOperator.instance.stubs(:create_raw_transaction).returns('RAW_TRANSACTION_HASH_STUB')
  XCoinOperator.instance.stubs(:connection).returns(bitcoin_client)
  operational_currencies = Array.new
  operational_currencies.push({ :name => 'darkcoin' })
  XCoinOperator.instance.stubs(:operational_currencies).returns(operational_currencies)
  XCoinOperator.instance.stubs(:scan_for_unspent_transactions).returns(unspent)
end
