require 'bitcoin'
require 'httparty'

require_relative 'btc_sender/engine'
require_relative 'btc_sender/blockchain'
require_relative 'btc_sender/address'

module BtcSender
  require 'pry'
  ::Bitcoin.network = :testnet3
  b = Blockchain.new
  a = Address.new(Bitcoin::Key).restore
  e = Engine.new(a, b)
  binding.pry
end
