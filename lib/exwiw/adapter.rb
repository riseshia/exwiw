# frozen_string_literal: true

module Exwiw
  module Adapter
    class Base
      attr_reader :connection_config

      def initialize(connection_config, logger)
        @connection_config = connection_config
        @logger = logger
      end
    end

    # @params [Exwiw::QueryAst] query_ast
    def execute(query_ast)
      raise NotImplementedError
    end

    # @params [Array<Array<String>>] array of rows
    # @params [Exwiw::Table] table
    def to_bulk_insert(results, table)
      raise NotImplementedError
    end

    # @params [Exwiw::QueryAst] select_query_ast
    # @params [Exwiw::Table] table
    def to_bulk_delete(select_query_ast, table)
      raise NotImplementedError
    end

    def self.build(connection_config, logger)
      case connection_config.adapter
      when 'sqlite3'
        Adapter::Sqlite3Adapter.new(connection_config, logger)
      when 'mysql2'
        Adapter::Mysql2Adapter.new(connection_config, logger)
      when 'postgresql'
        Adapter::PostgresqlAdapter.new(connection_config, logger)
      else
        raise 'Unsupported adapter'
      end
    end
  end
end
