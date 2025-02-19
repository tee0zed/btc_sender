# frozen_string_literal: true

require_relative 'utils/errors'
require 'httparty'

module BtcSender
  class Blockchain
    include HTTParty

    SIGNET_BASE_URI = 'https://mempool.space/signet/api'
    MAINNET_BASE_URI = 'https://mempool.space/api'
    TESTNET_BASE_URI = 'https://blockstream.info/testnet/api/'

    def initialize(network: :mainnet)
      self.class.base_uri(
        case network
        when :signet
          SIGNET_BASE_URI
        when :testnet
          TESTNET_BASE_URI
        else
          MAINNET_BASE_URI
        end
      )
    end

    def get_utxos(address)
      handle_request { self.class.get("/address/#{address}/utxo") }
    end

    def get_tx(txid)
      with_cache(txid) { handle_request { self.class.get("/tx/#{txid}") } }
    end

    def get_raw_tx(txid)
      with_cache("raw_#{txid}") { handle_request { self.class.get("/tx/#{txid}/raw") } }
    end

    def relay_tx(hex)
      handle_request { self.class.post('/tx', body: hex) }
    end

    private

    def handle_request
      response = yield
    rescue StandardError, OpenSSLError => e
      raise BtcSender::ConnectionError, e.message
    else
      raise BtcSender::ConnectionError, "Request failed: #{response.code} #{response.body}" unless response.success?

      response
    end

    def cache
      @cache ||= {}
    end

    def with_cache(tx_id)
      cache.fetch(tx_id) { cache[tx_id] = yield }
    end
  end
end
