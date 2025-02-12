# frozen_string_literal: true

module Exwiw
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load "tasks/exwiw.rake"
    end
  end
end
