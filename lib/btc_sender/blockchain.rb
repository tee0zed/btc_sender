require_relative 'utils/errors'

module BtcSender
  class Blockchain
    SIGNET_BASE_URI = 'https://mempool.space/signet/api'.freeze
    MAINNET_BASE_URI = 'https://mempool.space/api'.freeze

    attr_reader :_client
    def initialize(signet: true)
      @_client = built_client(signet ? SIGNET_BASE_URI : MAINNET_BASE_URI)
    end

    def get_utxos(address)
      handle_request { _client.get("/address/#{address}/utxo") }
    end

    def get_tx(txid)
      with_cache(txid) { handle_request { _client.get("/tx/#{txid}") }  }
    end

    def get_raw_tx(txid)
      with_cache("raw_#{txid}") { handle_request { _client.get("/tx/#{txid}/raw") } }
    end

    def relay_tx(hex)
      handle_request {  _client.post("/tx", body: hex) }
    end

    private

    def handle_request
      response = yield
    rescue StandardError => e
      raise BtcSender::ConnectionError, e.message
    else
      raise BtcSender::ConnectionError, "Request failed: #{response.code.to_s} #{response.body}" unless response.success?
      response
    end

    def built_client(base_uri)
      Class.new do
        include HTTParty
        base_uri(base_uri)
      end
    end

    def cache
      @cache ||= {}
    end

    def with_cache(tx_id)
      cache.fetch(tx_id) { cache[tx_id] = yield }
    end
  end
end
