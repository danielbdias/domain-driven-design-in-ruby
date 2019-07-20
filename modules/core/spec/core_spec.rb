require "spec_helper"

RSpec.describe Core do
  it do
    expect(Core).to be_kind_of(Module)
    expect(Core::VERSION).to eq "0.0.1"
  end
end
