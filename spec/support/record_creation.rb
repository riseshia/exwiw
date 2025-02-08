# frozen_string_literal: true

5.times do |i|
  company = Company.create(name: "Company \\#{i + 1}")
  2.times do |j|
    company.users.create(name: "User \\#{j + 1}", email: "user\\#{j + 1}@company\\#{i + 1}.com")
  end
end
