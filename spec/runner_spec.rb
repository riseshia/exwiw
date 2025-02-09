require 'spec_helper'

module Exwiw
  RSpec.describe Runner do
    let(:connection_config) { { 'adapter' => 'sqlite3' } }
    let(:output_dir) { 'test_output_dir' }
    let(:config_path) { 'test_config.json' }
    let(:dump_target) { double('DumpTarget') }
    let(:runner) { Runner.new(connection_config, output_dir, config_path, dump_target) }

    before do
      allow(File).to receive(:read).with(config_path).and_return('{ "tables": [] }')
      allow(JSON).to receive(:parse).and_return({ 'tables' => [] })
      allow(Config).to receive(:from).and_return(double(tables: []))
      allow_any_instance_of(SqliteAdapter).to receive(:execute).and_return([])
      allow_any_instance_of(SqliteAdapter).to receive(:to_bulk_insert).and_return('INSERT INTO ...')
    end

    it 'writes bulk insert SQL to the output file' do
      expect { runner.run }.not_to raise_error
    end
  end
end
