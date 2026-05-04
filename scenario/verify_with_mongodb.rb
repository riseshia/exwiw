require_relative './mongodb_client'

database_name = ARGV.shift
raise "database name required" if database_name.nil? || database_name.empty?

client = MongodbScenario.client(database_name)

expected = {
  "shops" => 1,
  "users" => 2,
  "orders" => 6,
  "order_items" => 6,
  "products" => 3,
  "transactions" => 6,
}

failed = false
expected.each do |collection, want|
  got = client[collection].count_documents({})
  if got == want
    puts "OK  #{collection}: #{got}"
  else
    puts "NG  #{collection}: expected #{want}, got #{got}"
    failed = true
  end
end

# Embedded `posts` should not be dumped as its own collection.
posts_count = client["posts"].count_documents({})
if posts_count.zero?
  puts "OK  posts collection not created (embedded)"
else
  puts "NG  posts collection unexpectedly populated: #{posts_count}"
  failed = true
end

# Verify masking of users.email
sample = client["users"].find({ "_id" => 1 }).first
if sample && sample["email"] == "masked1@example.com"
  puts "OK  users._id=1 email masked: #{sample["email"]}"
else
  puts "NG  users._id=1 email masking failed: #{sample.inspect}"
  failed = true
end

# Verify masking of embedded users.posts[].title
embedded_titles = (sample && sample["posts"] || []).map { |p| p["title"] }
expected_titles = ["masked-title-101", "masked-title-102"]
if embedded_titles == expected_titles
  puts "OK  users._id=1 embedded posts titles masked: #{embedded_titles.inspect}"
else
  puts "NG  users._id=1 embedded posts titles unexpected: #{embedded_titles.inspect}"
  failed = true
end

client.close
exit(failed ? 1 : 0)
