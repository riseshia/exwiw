require 'spec_helper'
require 'fileutils'
require 'json'

module Exwiw
  RSpec.describe Runner do
    let(:connection_config) do
      ConnectionConfig.new(
        adapter: 'sqlite3',
        database_name: 'tmp/test.sqlite3',
        host: nil,
        port: nil,
        user: nil,
        password: nil,
      )
    end
    let(:output_dir) { 'tmp/test_output_dir' }
    let(:config_dir) { 'test_config' }
    let(:dump_target) { double('DumpTarget') }
    let(:runner) do
      Runner.new(
        connection_config: connection_config,
        output_dir: output_dir,
        config_dir: config_dir,
        dump_target: dump_target,
        logger: ::Logger.new(nil),
      )
    end

    it 'writes bulk insert SQL to the output file' do
      expect { runner.run }.not_to raise_error
    end

    describe 'with bulk_insert_chunk_size' do
      let(:config_dir) { 'tmp/runner_spec_config' }
      let(:output_dir) { 'tmp/runner_spec_output' }
      let(:dump_target) { DumpTarget.new(table_name: 'shops', ids: ['1', '2', '3', '4', '5']) }
      let(:insert_sql_regex) { /INSERT INTO shops .+ VALUES\n\([^)]+\)(?:,\n\([^)]+\))*;/ }

      before do
        FileUtils.rm_rf(config_dir)
        FileUtils.rm_rf(output_dir)
        FileUtils.mkdir_p(config_dir)

        shops_config = JSON.parse(File.read('scenario/sqlite3-schema/shops.json'))
        shops_config['bulk_insert_chunk_size'] = 2
        File.write(File.join(config_dir, 'shops.json'), JSON.dump(shops_config))
      end

      it 'splits INSERT statements into chunks within a single file' do
        runner.run

        sql_file = Dir[File.join(output_dir, 'insert-*-shops.sql')].first
        expect(sql_file).not_to be_nil

        insert_statements = File.read(sql_file).scan(insert_sql_regex)
        expect(insert_statements.size).to eq(3)
      end
    end

    describe 'without bulk_insert_chunk_size' do
      let(:config_dir) { 'tmp/runner_spec_config_nochunk' }
      let(:output_dir) { 'tmp/runner_spec_output_nochunk' }
      let(:dump_target) { DumpTarget.new(table_name: 'shops', ids: ['1', '2', '3', '4', '5']) }

      before do
        FileUtils.rm_rf(config_dir)
        FileUtils.rm_rf(output_dir)
        FileUtils.mkdir_p(config_dir)

        FileUtils.cp('scenario/sqlite3-schema/shops.json', File.join(config_dir, 'shops.json'))
      end

      it 'emits a single INSERT statement per table' do
        runner.run

        sql_file = Dir[File.join(output_dir, 'insert-*-shops.sql')].first
        expect(sql_file).not_to be_nil

        sql = File.read(sql_file)
        expect(sql.scan(/INSERT INTO shops/).size).to eq(1)
      end
    end
  end
end
