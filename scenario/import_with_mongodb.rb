require 'json'

require_relative './mongodb_client'

database_name = ARGV.first
raise "database name required" if database_name.nil? || database_name.empty?

client = MongodbScenario.client(database_name)

# MongoDB adapter does not emit delete-*.jsonl, so drop each target collection first.
files = Dir.glob("tmp/mongodb/insert-*.jsonl").sort

files.each do |path|
  collection_name = File.basename(path, ".jsonl").sub(/\Ainsert-\d+-/, "")
  puts "Drop #{collection_name}"
  client[collection_name].drop
end

files.each do |path|
  collection_name = File.basename(path, ".jsonl").sub(/\Ainsert-\d+-/, "")
  puts "Import #{path} -> #{collection_name}"
  docs = File.readlines(path, chomp: true).reject(&:empty?).map { |line| JSON.parse(line) }
  client[collection_name].insert_many(docs) unless docs.empty?
end

client.close
