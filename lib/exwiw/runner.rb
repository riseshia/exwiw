# frozen_string_literal: true

require "fileutils"

module Exwiw
  class Runner
    def initialize(connection_config, output_dir, config_path, dump_target)
      @connection_config = connection_config
      @output_dir = output_dir
      @config_path = config_path
      @dump_target = dump_target
    end

    def run
      config = load_config
      adapter = build_adapter

      ordered_tables = DetermineTableProcessingOrder.run(config.tables)

      if !Dir.exist?(@output_dir)
        FileUtils.mkdir_p(@output_dir)
      end

      ordered_tables.each do |table|
        query = QueryAstBuilder.run(table, config.tables, @dump_target)
        results = adapter.execute(query)
        insert_sql = adapter.to_bulk_insert(results, table)

        File.open(File.join(@output_dir, "#{table}.sql"), 'w') do |file|
          file.puts(insert_sql)
        end
      end
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
