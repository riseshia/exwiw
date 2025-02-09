# frozen_string_literal: true

module Exwiw
  module Adapter
    class Base
      def initialize(connection_config)
        @connection_config = connection_config
      end
    end

    def execute(query)
      raise NotImplementedError
    end

    def to_bulk_insert(results, table)
      raise NotImplementedError
    end

    def self.build(connection_config)
      case connection_config.adapter
      when 'sqlite3'
        Adapter::SqliteAdapter.new(connection_config)
      else
        raise 'Unsupported adapter'
      end
    end
  end
end
