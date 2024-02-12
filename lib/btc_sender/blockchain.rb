module BtcSender
  class Blockchain
    TESTNET_BASE_URI = 'https://blockstream.info/testnet/api/'.freeze
    MAINNET_BASE_URI = 'https://blockstream.info/api/'.freeze

    attr_reader :_client
    def initialize(testnet: true)
      @_client = built_client(testnet ? TESTNET_BASE_URI : MAINNET_BASE_URI)
    end

    def get_utxos(address)
      handle_request { _client.get("/address/#{address}/utxo") }
    end

    def get_tx(txid)
      handle_request { _client.get("/tx/#{txid}") }
    end

    def relay_tx(hex)
      handle_request {  _client.post("/tx", body: hex) }
    end

    private

    def handle_request
      response = yield
    rescue StandardError => e
      raise ConnectionError, e.message
    else
      raise ConnectionError, 'Request failed: ' + response.code.to_s unless response.success?
      response
    end

    def built_client(base_uri)
      Class.new do
        include HTTParty
        base_uri(base_uri)
      end
    end
  end

  class ConnectionError < StandardError; end
end
