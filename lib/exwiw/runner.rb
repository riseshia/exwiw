# frozen_string_literal: true

module Exwiw
  class Runner
    def initialize(connection_config, output_path, config_path)
      @connection_config = connection_config
      @output_path = output_path
      @config_path = config_path
    end

    def run
      config = load_config
      adapter = build_adapter

      dump_queries = DumpQueryBuilder.new(config.tables).run

      sqls = dump_queries.map { |q| adapter.to_sql(q) }

      sqls.join("\n")
      puts @config.tables
    end

    private def load_config
      json = JSON.parse(File.read(@config_path))
      Config.from(json)
    end

    private def build_adapter
      case @connection_config["adapter"]
      when "sqlite3"
        SqliteAdapter.new(@connection_config)
      else
        raise "Unsupported adapter"
      end
    end
  end
end
