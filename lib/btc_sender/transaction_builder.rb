require 'btc_sender/utils/threadable'

module BtcSender
  class TransactionBuilder
    include Utils::Threadable
    include Bitcoin::Builder

    SAT_PER_BYTE = 39
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
      raise InvalidTransactionError, e.message
    end

    private

    def check_tx!
      raise InvalidTransactionError, 'Transaction not built' unless tx
    end

    def check_balance!
      raise InsufficientFundsError, "Insufficient funds #{balance} < #{amount + commission}" if balance < amount + commission
    end

    def build_raw_tx
      @tx ||= ::Bitcoin::Protocol::Tx.new.tap do |tx|
        add_inputs(tx)
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
      Bitcoin::Script.to_signature_pubkey_script(
        key.sign(signature),
        key.pub.htb,
        HASH_TYPE
      )
    end

    class InsufficientFundsError < StandardError; end
    class InvalidTransactionError < StandardError; end
  end
end
