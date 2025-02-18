# frozen_string_literal: true

require 'forwardable'

module BtcSender
  class Key
    extend Forwardable

    DEFAULT_WIF_PATH = './wif.txt'
    ADDRESSES_TYPES = %i[p2wpkh p2wsh].freeze

    def_delegators :@instance, :pubkey, :to_wif, :sign
    attr_reader :key_provider, :type, :instance

    def initialize(key_provider, type: :p2wpkh)
      @key_provider = key_provider
      @type = ADDRESSES_TYPES.include?(type) ? type : :p2wpkh
      @instance = nil
    end

    def restore(wif_path: DEFAULT_WIF_PATH, wif_string: nil)
      if wif_string
        from_string(wif_string)
      else
        from_file(wif_path)
      end
    rescue Errno::ENOENT
      generate_and_save
    end

    def from_string(wif)
      @instance = key_provider.from_wif(wif)
    end

    def from_file(wif_path = DEFAULT_WIF_PATH)
      from_string(File.read(wif_path).strip)
    end

    def generate_and_save
      @instance = key_provider.generate.tap do |k|
        safe_save(k.to_wif)
      end
    end

    def to_address
      instance.public_send("to_#{type}")
    end

    private

    def safe_save(wif)
      if Dir['*wif*'].empty?
        File.write(DEFAULT_WIF_PATH, wif)
      else
        File.write("#{DEFAULT_WIF_PATH}__#{Process.clock_gettime(Process::CLOCK_REALTIME)}", wif)
      end
    end
  end
end
