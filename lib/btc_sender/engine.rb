module BtcSender
  class Engine
    include Bitcoin::Builder

    attr_accessor :key, :blockchain_provider
    def initialize(key, blockchain_provider)
      @blockchain_provider = blockchain_provider
      @key = key
    end

    def get_raw_balance
      utxos.reduce(0) { |sum, utxo| sum + utxo['value'] }
    end

    def get_spendable_balance
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

    def spendable_utxos_txs
      spendable_utxos.map { |utxo| blockchain_provider.get_tx(utxo['txid']).parsed_response }
    end
  end
end
