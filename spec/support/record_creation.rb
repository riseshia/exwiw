# frozen_string_literal: true

time = Time.parse("2025-01-01 00:00:00 UTC")

5.times do |i|
  shop = Shop.create(name: "Shop #{i + 1}", created_at: time, updated_at: time)
  users = []
  2.times do |j|
    users << User.create(name: "User #{j + 1}", email: "user#{j + 1}@example.com", shop: shop, created_at: time, updated_at: time)
  end
  products = []
  3.times do |k|
    products << Product.create(name: "Product #{k + 1}", price: (k + 1) * 10, shop: shop, created_at: time, updated_at: time)
  end
  users.each do |user|
    products.each do |product|
      order = Order.create(shop: shop, user: user, created_at: time, updated_at: time)
      order_item = OrderItem.create(order: order, product: product, created_at: time, updated_at: time)
      PaymentTransaction.create(order: order, amount: order_item.product.price * order_item.quantity, created_at: time, updated_at: time)
      Review.create(reviewable: product, user: user, rating: rand(1..5), content: "Review for #{product.name} by #{user.name}", created_at: time, updated_at: time)
    end
  end
end

3.times do |i|
  SystemAnnouncement.create(title: "Announcement #{i + 1}", content: "This is the content of announcement #{i + 1}.")
end
