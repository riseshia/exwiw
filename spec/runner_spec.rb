require 'spec_helper'

module Exwiw
  RSpec.describe Runner do
    let(:connection_config) do
      ConnectionConfig.new(
        adapter: 'sqlite3',
        database_name: ':memory:',
        host: nil,
        port: nil,
        user: nil,
        password: nil,
      )
    end
    let(:output_dir) { 'test_output_dir' }
    let(:config_path) { 'test_config.json' }
    let(:dump_target) { double('DumpTarget') }
    let(:runner) { Runner.new(connection_config, output_dir, config_path, dump_target) }

    before do
      allow(File).to receive(:read).with(config_path).and_return('{ "adapter": "sqlite3", "tables": [] }')
      allow_any_instance_of(Adapter::SqliteAdapter).to receive(:execute).and_return([])
      allow_any_instance_of(Adapter::SqliteAdapter).to receive(:to_bulk_insert).and_return('INSERT INTO ...')
    end

    it 'writes bulk insert SQL to the output file' do
      expect { runner.run }.not_to raise_error
    end
  end
end
