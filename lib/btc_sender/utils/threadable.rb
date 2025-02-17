require 'concurrent'

module BtcSender
  module Utils
    module Threadable
      refine Array do
        def threaded_map
          return map unless block_given?

          threads = []
          each_with_index do |item, i|
            threads << ::Thread.new do
              self[i] = yield(item)
            end
          end

          threads.each(&:join)
          self
        end

        def threaded_each
          return each unless block_given?

          threads = []
          each_with_index do |item, i|
            threads << ::Thread.new do
              yield(item)
            end
          end

          threads.each(&:join)
          self
        end
      end
    end
  end
end
