# frozen_string_literal: true

module Entities
  class Bitcoin
    def initialize(satoshis)
      raise ArgumentError, 'Satoshis must be an Integer' unless satoshis.respond_to?(:odd?)

      @satoshis = satoshis
    end

    def inspect
      "#{to_btc} BTC (#{@satoshis} satoshi" + (@satoshis == 1 ? ')' : 's)')
    end

    def to_btc
      satoshis = @satoshis.to_s
      if satoshis.to_s.size > 8
        satoshis.to_s.insert(-9, '.')
      else
        "0.#{satoshis.to_s.rjust(8, '0')}"
      end
    end

    def to_satoshis
      @satoshis
    end
    alias to_i to_satoshis
    alias value to_satoshis
  end
end
