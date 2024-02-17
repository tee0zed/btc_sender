module BtcSender
  module Utils
    module Threadable
      def threaded_job(collection)
        collection.each_with_index.map do |item, i|
          Thread.new { yield(item, i) }
        end.map(&:join)
      end
    end
  end
end
