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
        to be(0.01014006)
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
  it 'can spot that accumulated dust inputs are not eligible for sending'
  it 'locks inputs before creating raw transaction'
  it 'unlocks inputs before signing transaction' # Do we need to unlock?
  it 'creates new address before sending'
  it 'validates transaction before sending'
  # it 'sends accumulated transaction to the net'
end
