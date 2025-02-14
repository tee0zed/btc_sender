require 'httparty'
require 'bitcoin'
require 'pry'
require './lib/btc_sender/utils/patches/bitcoin.rb'

require_relative 'btc_sender/engine'
require_relative 'btc_sender/blockchain'
require_relative 'btc_sender/address'

module BtcSender
end
