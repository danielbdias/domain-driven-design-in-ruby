require "spec_helper"

RSpec.describe Core::Entity do
  context "when class inherits from Core::Entity" do
    class MockedEntity < Core::Entity

      attribute :id, Types::Strict::Integer.optional
      attribute :number, Types::Strict::String

    end

    it "allows omitted values" do
      record = MockedEntity.new(number: "aaa")
      expect(record.id).to eq nil
      expect(record.number).to eq "aaa"
    end

    it "allows sym values" do
      record = MockedEntity.new(id: nil, number: "123")
      expect(record.id).to eq nil
      expect(record.number).to eq "123"
    end

    it "allows string values" do
      record = MockedEntity.new("id" => 1, "number" => "1234")
      expect(record.id).to eq 1
      expect(record.number).to eq "1234"
    end

    it "responds to attributes" do
      record = MockedEntity.new("id" => 123, "number" => "4321")
      expect(record.attributes).to eq(id: 123, number: "4321")
    end

    it "allows attribute to be setted" do
      record = MockedEntity.new("id" => 123, "number" => "4321")
      record.id = 321
      expect(record.id).to eq(321)
      record.number = "number"
      expect(record.number).to eq("number")
      expect(record.attributes).to eq(id: 321, number: "number")
    end

    it "allows attributes to be setted" do
      record = MockedEntity.new("id" => 123, "number" => "4321")
      record.attributes = { id: 321, number: "number" }
      expect(record.id).to eq(321)
      expect(record.number).to eq("number")
      expect(record.attributes).to eq(id: 321, number: "number")
    end

    it "allows attributes to be assigned" do
      record = MockedEntity.new("id" => 123, "number" => "4321")
      record.assign_attributes(number: "number")
      expect(record.id).to eq(123)
      expect(record.number).to eq("number")
      expect(record.attributes).to eq(id: 123, number: "number")
    end
  end

  describe "Types::UUID" do
    Types = described_class::Types

    let(:uuid) { SecureRandom.uuid }
    let(:bad_uuid) { "#{uuid}&" }

    it "raises when is empty" do
      expect { Types::UUID[""] }.to raise_error(Dry::Types::ConstraintError)
    end

    it "returns uuid when is valid" do
      expect(Types::UUID[uuid]).to eq(uuid)
    end

    it "raises when is in invalid format" do
      expect { Types::UUID[bad_uuid] }.to raise_error(Dry::Types::ConstraintError)
    end
  end
end
