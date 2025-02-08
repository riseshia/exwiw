# frozen_string_literal: true

5.times do |i|
  shop = Shop.create(name: "Shop #{i + 1}")
  users = []
  2.times do |j|
    users << User.create(name: "User #{j + 1}", email: "user#{j + 1}@example.com", shop: shop)
  end
  products = []
  3.times do |k|
    products << Product.create(name: "Product #{k + 1}", price: (k + 1) * 10, shop: shop)
  end
  users.each do |user|
    products.each do |product|
      order = Order.create(shop: shop, user: user)
      order_item = OrderItem.create(order: order, product: product)
      PaymentTransaction.create(order: order, amount: order_item.product.price * order_item.quantity)
      Review.create(reviewable: product, user: user, rating: rand(1..5), content: "Review for #{product.name} by #{user.name}")
    end
  end
end
