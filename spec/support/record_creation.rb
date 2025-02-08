# frozen_string_literal: true

5.times do |i|
  shop = Shop.create(name: "Shop \\#{i + 1}")
  2.times do |j|
    User.create(name: "User \\#{j + 1}", email: "user\\#{j + 1}@example.com", shop: shop)
  end
end
