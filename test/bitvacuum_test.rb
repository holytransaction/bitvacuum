require 'test_helper'

describe 'BitVacuum' do
  it 'establishes connection with XCOIN RPC server'
  it 'scans for unspent transactions with value below threshold'
  it 'calculates transaction size'
  it 'calculates value of multiple inputs'
  it 'accumulates dust inputs into valid free from fees transaction'
  it 'can spot that there is no dust in the wallet'
  it 'can spot that accumulated dust inputs are not eligible for sending'
  it 'can rearrange inputs if size of the output transaction exceeds maximum size'
  # it 'sends accumulated transaction to the net'
end
