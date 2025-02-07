# frozen_string_literal: true

RSpec.describe Exwiw::Config do
  context "simple config" do
    let(:config_obj) do
      {
        "database" => {
          "adapter" => "mysql",
          "name" => "app_prod",
        },
        "tables" => []
      }
    end

    it "par useful" do
      expect(Exwiw::Config.from(config_obj)).to be_a(Exwiw::Config)
    end
  end
end
