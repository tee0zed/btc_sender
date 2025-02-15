require './lib/btc_sender/utils/threadable'
require './lib/btc_sender/utils/errors'
require 'bitcoin'

module BtcSender
  class TransactionBuilder
    include Utils::Threadable

    SAT_PER_BYTE = 2
    HASH_TYPE = ::Bitcoin::SIGHASH_TYPE[:all]

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

      check_balance!
      add_commission

      self
    end

    def sign_tx(key)
      check_tx!

      require 'pry';
      binding.pry

      tx.inputs.each_with_index do |input, i|
        utxo = opts[:utxos][i]
        prev_out = Bitcoin::Tx.parse_from_payload(utxo['raw_tx']).outputs[utxo['vout']]
        prev_script_pubkey = prev_out.script_pubkey
        sig_hash = tx.sighash_for_input(i, prev_script_pubkey, amount: prev_out.value, hash_type: HASH_TYPE)
        signature = key.sign(sig_hash)

        input.script_sig = Bitcoin::Script.new
        input.script_sig << signature
        input.script_sig << key.pubkey

        if input.has_witness?
          input.witness = []
          input.witness << signature
          input.witness << key.pubkey
        end
      end

      true
    rescue StandardError => e
      raise BtcSender::InvalidTransactionError, e.message
    end

    def tx_payload
      tx.to_payload.bth
    end

    private

    def check_tx!
      raise BtcSender::InvalidTransactionError, 'Transaction not built' unless tx
    end

    def check_balance!
      raise BtcSender::InsufficientFundsError, "Insufficient funds #{balance} < #{amount + commission}" if balance < amount + commission
    end

    def build_raw_tx
      @tx ||= Bitcoin::Tx.new.tap do |tx|
        add_inputs(tx)
        tx.outputs << output(amount, to_address(to))
        tx.outputs << output(balance - amount, to_address(from)) if balance > amount
      end

      self
    rescue StandardError => e
      raise BtcSender::InvalidTransactionError, e.message
    end

    def add_inputs(tx)
      opts[:utxos].each do |utxo|
        tx.in << input(utxo)
      end
    end

    def input(utxo)
      Bitcoin::TxIn.new(
        out_point: Bitcoin::OutPoint.new(utxo['txid'].htb.reverse, utxo['vout'])
      )
    end

    def output(amount, to)
      Bitcoin::TxOut.new(
        value: amount,
        script_pubkey: to
      )
    end

    def to_address(address)
      Bitcoin::Script.parse_from_addr(address)
    end

    def balance
      opts[:utxos].sum { |utxo| utxo['value'] }
    end

    def add_commission
      tx.outputs.last.value -= commission
    end

    def commission
      opts[:commission] || (tx.to_payload.bytesize * (opts[:commission_multiplier].to_f || 1) * SAT_PER_BYTE)
    end
  end
end
