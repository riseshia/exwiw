# frozen_string_literal: true

5.times do |i|
  shop = Shop.create(name: "Shop \\#{i + 1}")
  2.times do |j|
    User.create(name: "User \\#{j + 1}", email: "user\\#{j + 1}@example.com", shop: shop)
  end
  3.times do |k|
    Product.create(name: "Product \\#{k + 1}", price: (k + 1) * 10, shop: shop)
  end
end
