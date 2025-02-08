# frozen_string_literal: true

5.times do |i|
  Company.create(name: "Company \\#{i + 1}")
end
