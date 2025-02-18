require './lib/btc_sender/transaction_builder'
require_relative 'utils/errors'
require_relative 'utils/threadable'

module BtcSender
  class Engine
    using Utils::Threadable

    attr_reader :key, :blockchain
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
      @utxos ||= begin
        blockchain.get_utxos(key.to_address).parsed_response.threaded_each do |utxo|
          utxo['raw_tx'] = blockchain.get_raw_tx(utxo['txid']).body
        end
      end
    end

    def refresh_utxos
      @utxos = nil
      utxos
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
      TransactionBuilder.new(amount, to, key.to_address, utxos:, commission_multiplier: opts[:commission_multiplier], blockchain:)
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
