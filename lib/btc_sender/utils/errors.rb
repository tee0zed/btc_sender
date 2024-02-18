module BtcSender
  class CLIError < StandardError
    def backtrace
      super.try(:[], 0..1)
    end
  end
  class InvalidTransactionError < CLIError; end
  class InsufficientFundsError < CLIError; end
  class SignatureError < CLIError; end
  class ConnectionError < CLIError; end
end
