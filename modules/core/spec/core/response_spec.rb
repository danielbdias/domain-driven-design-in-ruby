require "spec_helper"

RSpec.describe Core::Response do
  describe ".success" do
    subject { described_class.success("done") }

    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }
    it { is_expected.to have_attributes(content: "done") }
  end

  describe ".failure" do
    subject { described_class.failure("error") }

    it { is_expected.to be_failure }
    it { is_expected.not_to be_success }
    it { is_expected.to have_attributes(content: "error") }
  end

  describe "#success?" do
    subject { described_class.new :success }

    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }
    it { is_expected.to have_attributes(content: nil) }
  end

  describe "#failure?" do
    subject { described_class.new :failure }

    it { is_expected.to be_failure }
    it { is_expected.not_to be_success }
    it { is_expected.to have_attributes(content: nil) }
  end

  describe "#content" do
    it "wraps any object" do
      expect(described_class.success({})).to have_attributes(content: {})
      expect(described_class.success("string")).to have_attributes(content: "string")
      expect(described_class.success(12.33)).to have_attributes(content: 12.33)
      expect(described_class.success(false)).to have_attributes(content: false)
    end
  end

  describe "#[]" do
    subject(:success) { described_class.success("done") }

    context "when method/attr exists" do
      it "call the method and return the result" do
        expect(success[:status]).to eq :success
      end
    end

    context "when method/attr do not exists" do
      it "return nil" do
        expect(success[:unknown]).to be_nil
      end
    end
  end

  describe "#dig" do
    let(:response) { described_class.success(sublevel: "content") }

    it "returns value if respond to method" do
      expect(response.dig(:status)).to eq(:success)
      expect(response.dig("status")).to eq(:success)
      expect(response.dig(:content, :sublevel)).to eq("content")
    end

    it "returns nil not respond to method" do
      expect(response.dig(:unknown)).to eq nil
    end
  end
end
