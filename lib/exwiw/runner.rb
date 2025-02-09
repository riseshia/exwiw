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

      ordered_table_names = DetermineTableProcessingOrder.run(config.tables)

      if !Dir.exist?(@output_dir)
        FileUtils.mkdir_p(@output_dir)
      end

      ordered_table_names.each do |table_name|
        query = QueryAstBuilder.run(table_name, config.tables, @dump_target)
        results = adapter.execute(query)
        insert_sql = adapter.to_bulk_insert(results, table_name)

        File.open(File.join(@output_dir, "#{table_name}.sql"), 'w') do |file|
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
