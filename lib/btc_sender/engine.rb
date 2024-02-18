require './lib/btc_sender/transaction_builder'
require_relative 'utils/errors'

module BtcSender
  class Engine
    attr_accessor :key, :blockchain
    def initialize(key:, blockchain:)
      @blockchain = blockchain
      @key = key
    end

    def raw_balance
      utxos.reduce(0) { |sum, utxo| sum + utxo['value'] }
    end

    def spendable_balance
      spendable_utxos.reduce(0) { |sum, utxo| sum + utxo['value'] }
    end

    def spendable_utxos
      utxos.select { |utxo| utxo.dig('status', 'confirmed') }
    end

    def utxos
      @utxos ||= blockchain.get_utxos(key.addr)
    end

    def refresh_utxos
      @utxos = blockchain.get_utxos(key.addr)
    end

    def send_funds!(to, amount, opts = {})
      builder = tx_builder(to, amount, opts)
      builder.build_tx

      raise BtcSender::SignatureError unless builder.sign_tx(key)

      relay_tx(builder.tx_payload)
    end

    def relay_tx(hex)
      blockchain.relay_tx(hex)
    end

    def tx_builder(to, amount, opts = {})
      utxos = utxos_by_strategy(opts[:strategy] || :shrink, amount)
      TransactionBuilder.new(amount, to, key.addr, utxos: utxos, commission_multiplier: opts[:commission_multiplier], blockchain: blockchain)
    end

    private

    def fewest_utxos(amount)
      amount = amount.dup
      sorted = spendable_utxos.sort_by { |utxo| utxo['value'] }
      res = []

      while amount > 0 && sorted.any?
        sorted.pop.tap do |utxo|
          res << utxo
          amount -= utxo['value']
        end
      end

      res
    end

    def utxos_by_strategy(strategy, amount)
      case strategy
      when :shrink
        fewest_utxos(amount)
      else
        spendable_utxos
      end
    end
  end
end
