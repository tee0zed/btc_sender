module Entities
  class Transaction
    include Bitcoin::Builder

    SAT_PER_BYTE = 39

    attr_reader :amount, :to, :from, :tx, :opts
    def initialize(amount, to, from, opts = {})
      @opts = opts
      @amount = amount
      @to = to
      @from = from
      @tx = nil
    end

    def build_tx
      build_raw_tx

      raise InsufficientFundsError, "Insufficient funds #{balance} < #{amount + commission}" if balance < amount + commission
      add_commission

      self
    end

    def to_hex
      tx.to_payload.bth
    end

    private

    def build_raw_tx
      @tx ||= ::Bitcoin::Protocol::Tx.new.tap do |tx|
        opts[:utxos].each { |utxo| tx.add_in(input(utxo)) }
        tx.add_out(output(amount, to))
        tx.add_out(output(balance - amount, from))

      end

      self
    end

    def balance
      opts[:utxos].reduce(0) { |sum, utxo| sum + utxo['value'] }
    end

    def add_commission
      tx.out[1].value -= commission
    end

    def commission
      tx.to_payload.bytesize * (opts[:commission_multiplier] || 1) * SAT_PER_BYTE
    end

    def input(utxo)
      ::Bitcoin::Protocol::TxIn.new(utxo['txid'], utxo['vout'], 0)
    end

    def output(amount, to)
      ::Bitcoin::Protocol::TxOut.value_to_address(amount, to)
    end
    class InsufficientFundsError < StandardError; end
  end
end
