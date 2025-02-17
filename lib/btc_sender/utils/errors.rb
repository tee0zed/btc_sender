module BtcSender
  class CLIError < StandardError
    def backtrace
      super && super[0..1]
    end
  end
  class InvalidTransactionError < CLIError; end
  class InsufficientFundsError < CLIError; end
  class DustError < CLIError; end
  class SignatureError < CLIError; end
  class ConnectionError < CLIError; end
end
