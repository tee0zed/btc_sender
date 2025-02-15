require 'concurrent'

module BtcSender
  module Utils
    module Threadable
      refine Array do
        def threaded_each
          return each unless block_given?

          threads = map.with_index do |item, i|
            Thread.new { yield(item, i) }.value
          end

          threads.each(&:join)
        end

        def threaded_map
          return each unless block_given?

          collection = ::Concurrent::Array.new(size)
          threads = []

          each_with_index do |item, i|
            threads << Thread.new(item, i) do |item, i|
              collection[i] = yield(item, i)
            end
          end

          threads.each(&:join)
          collection
        end
      end
    end
  end
end
