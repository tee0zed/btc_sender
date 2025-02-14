require './lib/btc_sender/utils/threadable'
require './lib/btc_sender/utils/errors'
require 'bitcoin'

module BtcSender
  class TransactionBuilder
    include Utils::Threadable
    include Bitcoin::Builder

    SAT_PER_BYTE = 2
    HASH_TYPE = Bitcoin::Script::SIGHASH_TYPE[:all]

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

      threaded_job(tx.in) do |input, i|
        prev_tx = opts[:utxos][i]['tx']
        input.script_sig = script_signature(key,
          tx.signature_hash_for_input(i, prev_tx, HASH_TYPE)
        )

        tx.verify_input_signature(i, prev_tx)
      end.map(&:value).all?
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
      @tx ||= ::Bitcoin::Protocol::Tx.new.tap do |tx|
        add_inputs(tx)
        tx.add_out(output(amount, to))
        tx.add_out(output(balance - amount, from))
      end

      self
    rescue StandardError => e
      raise BtcSender::InvalidTransactionError, e.message
    end

    def balance
      opts[:utxos].reduce(0) { |sum, utxo| sum + utxo['value'] }
    end

    def add_commission
      tx.out[1].value -= commission
    end

    def commission
      opts[:commission] || (tx.to_payload.bytesize * (opts[:commission_multiplier].to_f || 1) * SAT_PER_BYTE)
    end

    def add_inputs(tx)
      threaded_job(opts[:utxos]) do |utxo|
        utxo['tx'] = prev_tx(utxo)
        tx.add_in(input(utxo))
      end
    end

    def input(utxo)
      ::Bitcoin::Protocol::TxIn.new(utxo['tx'].binary_hash, utxo['vout'], 0)
    end

    def prev_tx(utxo)
      ::Bitcoin::Protocol::Tx.new(
        opts[:blockchain].get_raw_tx(utxo['txid']).body
      )
    end

    def output(amount, to)
      ::Bitcoin::Protocol::TxOut.value_to_address(amount, to)
    end

    def script_signature(key, signature)
      digest = OpenSSL::Digest::SHA256.new
      message_hash = digest.digest(signature)

      Bitcoin::Script.to_signature_pubkey_script(
        key.sign(digest, message_hash),
        key.public_key.to_bn.to_s(2),
        HASH_TYPE
      )
    end
  end
end
