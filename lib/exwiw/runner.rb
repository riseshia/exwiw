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
      adapter = Adapter.build(@connection_config)

      ordered_table_names = DetermineTableProcessingOrder.run(config.tables)

      if !Dir.exist?(@output_dir)
        FileUtils.mkdir_p(@output_dir)
      end

      table_by_name = config.tables.each_with_object({}) { |table, hash| hash[table.name] = table }

      total_size = ordered_table_names.size
      ordered_table_names.each_with_index do |table_name, idx|
        table = table_by_name.fetch(table_name)

        query_ast = QueryAstBuilder.run(table.name, table_by_name, @dump_target)
        results = adapter.execute(query_ast)

        insert_sql = adapter.to_bulk_insert(results, table)
        insert_idx = (idx + 1).to_s.rjust(3, '0')
        File.open(File.join(@output_dir, "insert-#{insert_idx}-#{table_name}.sql"), 'w') do |file|
          file.puts(insert_sql)
        end

        delete_sql = adapter.to_bulk_delete(results, table)
        delete_idx = (total_size - idx).to_s.rjust(3, '0')
        File.open(File.join(@output_dir, "delete-#{delete_idx}-#{table_name}.sql"), 'w') do |file|
          file.puts(delete_sql)
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
        Sqlite3Adapter.new(@connection_config)
      else
        raise "Unsupported adapter"
      end
    end
  end
end
