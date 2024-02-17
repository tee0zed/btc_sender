require './lib/btc_sender/entities/transaction'

module BtcSender
  class Engine

    attr_accessor :key, :blockchain_provider
    def initialize(key, blockchain_provider)
      @blockchain_provider = blockchain_provider
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
      @utxos ||= blockchain_provider.get_utxos(key.addr)
    end

    def refresh_utxos
      @utxos = blockchain_provider.get_utxos(key.addr)
    end

    def send_funds!(to, amount, opts = {})
      utxos = utxos_by_strategy(opts[:strategy] || :all, amount)
      tx = Entities::Transaction.new(amount, to, key.addr, utxos: utxos, commission_multiplier: opts[:commission_multiplier])
      tx.build_tx.sign(key)
      blockchain_provider.relay_tx(tx.to_hex)
    end

    def sign_tx(tx)
      raise ArgumentError, 'Generate Tx first!' if tx.nil?

      tx.in.each_with_index do |input, index|
        Bitcoin.sign_data(private_key(key), tx.signature_hash_for_input(index, input.prev_out)).tap do |sig_hash|
          input.script_sig = Bitcoin::Script.to_signature_pubkey_script(sig_hash, binary_pubkey(key))
        end
      end
    end

    def private_key(key)
      Bitcoin.open_key(key.priv)
    end

    def binary_pubkey(key)
      [key.pub].pack('H*')
    end

    def fewest_utxos(amount)
      amount = amount.dup
      sorted = spendable_utxos.sort_by { |utxo| utxo['value'] }
      res = []

      while amount > 0 || sorted.empty?
        sorted.each do |utxo|
          if utxo['value'] >= amount || utxo.last?
            amount -= utxo['value']
            res << sorted.delete(utxo)
          end
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
