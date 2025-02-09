# frozen_string_literal: true

require 'optparse'
require 'pathname'

require 'json'

require 'exwiw'

module Exwiw
  class CLI
    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
      @help = argv.empty?

      @database_host = nil
      @database_port = nil
      @database_user = nil
      @database_password = ENV["DATABASE_PASSWORD"]
      @output_dir = "dump"
      @config_path = "schema.json"
      @database_adapter = nil
      @database_name = nil
      @target_table_name = nil
      @ids = []

      parser.parse!(@argv)
    end

    def run
      if @help
        puts parser.help
      else
        validate_options!

        connection_config = ConnectionConfig.new(
          host: @database_host,
          port: @database_port,
          user: @database_user,
          password: @database_password,
          database_name: @database_name,
        )

        dump_target = DumpTarget.new(
          table_name: @target_table_name,
          ids: @ids,
        )

        Runner.new(connection_config, @output_dir, @config_path, dump_target).run
      end
    end

    private def validate_options!
      if @database_adapter != "sqlite3"
        {
          "Target database host" => @database_host,
          "Target database port" => @database_port,
          "Database user" => @database_user,
          "Target database name" => @database_name,
        }.each do |k, v|
          if v.nil?
            $stderr.puts "#{k} is required"
            exit 1
          end
        end

        if @database_password.nil? || @database_password.empty?
          $stderr.puts "environment variable 'DATABASE_PASSWORD' is required"
          exit 1
        end
      end

      valid_adapters = ["mysql2", "pg", "sqlite3"]
      unless valid_adapters.include?(@database_adapter)
        $stderr.puts "Invalid adapter. Available options are: #{valid_adapters.join(', ')}"
        exit 1
      end

      if @target_table_name.nil? || @target_table_name.empty?
        $stderr.puts "Target table is required"
        exit 1
      end

      if @ids.empty?
        $stderr.puts "At least one ID is required"
        exit 1
      end
    end

    private def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "exwiw #{Exwiw::VERSION}"
        opts.version = Exwiw::VERSION

        opts.on("-h", "--host=HOST", "Target database host") { |v| @database_host = v }
        opts.on("-p", "--port=PORT", "Target database port") { |v| @database_port = v }
        opts.on("-u", "--user=USERNAME", "Target database user") { |v| @database_user = v }
        opts.on("-o", "--output-dir=[DUMP_DIR_PATH]", "Output file path. default is dump/") do |v|
          @output_dir = v.end_with?("/") ? v[0..-2] : v
        end
        opts.on("-c", "--config=[CONFIG_FILE_PATH]", "Config file path. default is schema.json") { |v| @config_path = v }
        opts.on("-a", "--adapter=ADAPTER", "Database adapter") { |v| @database_adapter = v }
        opts.on("--database=DATABASE", "Target database name") { |v| @database_name = v }
        opts.on("--target-table=TABLE", "Target table for extraction") { |v| @target_table_name = v }
        opts.on("--ids=IDS", "Comma-separated list of identifiers") { |v| @ids = v.split(',') }

        opts.on("--help", "Print this help") do
          @help = true
        end
      end
    end
  end
end
