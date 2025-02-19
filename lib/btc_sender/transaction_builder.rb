# frozen_string_literal: true

require './lib/btc_sender/utils/threadable'
require './lib/btc_sender/utils/errors'
require 'bitcoin'

module BtcSender
  class TransactionBuilder
    include Utils::Threadable

    DEFAULT_SAT_PER_BYTE = 2
    DUST_THRESHOLD = 546
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
      @tx = build_raw_tx

      check_balance!
      add_commission

      self
    end

    def sign_tx(key)
      check_tx!

      tx.in.each_with_index do |input, i|
        utxo = opts[:utxos][i]
        utxo_out = Bitcoin::Tx.parse_from_payload(utxo['raw_tx'].b).out[utxo['vout']]
        sign_input(input, utxo_out, i, key)
      end

      true
    end

    def tx_payload
      tx.to_payload.bth
    end

    private

    def sign_input(input_to_sign, utxo_out, input_index, key)
      out_pubkey = utxo_out.script_pubkey

      if out_pubkey.p2wpkh? || out_pubkey.p2wsh?
        sig_hash = tx.sighash_for_input(input_index, out_pubkey, sig_version: :witness_v0, amount: utxo_out.value)
        input_to_sign.script_witness.stack << signature(sig_hash, key)
        input_to_sign.script_witness.stack << key.pubkey.htb

        tx.verify_input_sig(input_index, out_pubkey, amount: utxo_out.value)
      else
        warn 'Signing legacy input'

        sig_hash = tx.sighash_for_input(input_index, out_pubkey)
        input_to_sign.script_sig << signature(sig_hash, key)
        input_to_sign.script_sig << key.pubkey.htb
      end
    end

    def signature(sig_hash, key)
      key.sign(sig_hash) + [HASH_TYPE].pack('C')
    end

    def check_tx!
      raise BtcSender::InvalidTransactionError, 'Transaction not built' unless tx
    end

    def check_balance!
      if balance < amount + commission
        raise BtcSender::InsufficientFundsError, "Insufficient funds (with commission) #{balance} < #{amount + commission}"
      end
      if amount < DUST_THRESHOLD
        raise BtcSender::DustError, "Amount is below dust threshold #{amount} < #{DUST_THRESHOLD}"
      end
    end

    def build_raw_tx
      Bitcoin::Tx.new.tap do |tx|
        add_inputs(tx)
        tx.outputs << output(amount, to)
        tx.outputs << output(balance - amount, from)
      end
    rescue => e
      raise BtcSender::InvalidTransactionError, e.message
    end

    def add_inputs(tx)
      opts[:utxos].each do |utxo|
        tx.in << input(utxo)
      end
    end

    def input(utxo)
      Bitcoin::TxIn.new(
        out_point: Bitcoin::OutPoint.from_txid(utxo['txid'], utxo['vout'])
      )
    end

    def output(amount, to)
      Bitcoin::TxOut.new(
        value: amount,
        script_pubkey: Bitcoin::Script.parse_from_addr(to)
      )
    end

    def balance
      opts[:utxos].sum { |utxo| utxo['value'] }
    end

    def add_commission
      change_output = tx.outputs.last.value - commission

      if change_output < DUST_THRESHOLD || change_output <= 0
        tx.outputs.pop
        new_required_fee = commission

        if tx.outputs.last.value < new_required_fee
          raise BtcSender::InsufficientFundsError,
            "Fee insufficient after adjusting for dust change. Required: #{new_required_fee}, Available: #{actual_fee}"
        end
      else
        tx.outputs.last.value = change_output
      end
    end

    def commission
      opts[:commission] || (tx.to_payload.bytesize * (opts[:commission_multiplier] || 1).to_f * DEFAULT_SAT_PER_BYTE)
    end
  end
end
