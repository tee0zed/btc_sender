module BtcSender
  class Address
    extend Forwardable

    DEFAULT_WIF_PATH = './wif.txt'.freeze

    def_delegators :@instance, :addr, :pub, :to_base58, :sign
    attr_reader :key_provider, :instance
    def initialize(key_provider)
      @key_provider = key_provider
      @instance = nil
    end

    def restore(wif_path = DEFAULT_WIF_PATH)
      from_file(wif_path)
    rescue Errno::ENOENT
      generate_and_save
    end

    def from_string(wif)
      @instance = key_provider.from_base58(wif)
    end

    def from_file(wif_path = DEFAULT_WIF_PATH)
      from_string(File.read(wif_path).strip)
    end

    def generate_and_save
      @instance = key_provider.generate.tap do |k|
        safe_save(k.to_base58)
      end
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
