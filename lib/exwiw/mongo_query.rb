# frozen_string_literal: true

module Exwiw
  module MongoQuery
    Find = Struct.new(:collection, :primary_key, :filter, :projection, keyword_init: true) do
      def to_h
        {
          collection: collection,
          primary_key: primary_key,
          filter: filter,
          projection: projection,
        }
      end
    end
  end
end
