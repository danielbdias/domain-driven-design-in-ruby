require "spec_helper"

RSpec.describe Core::Contract do
  context "when inherits from Core::Contract" do
    class MyMockedContract < Core::Contract

      params do
        required(:name).value(:string, size?: 2..30)
        optional(:last_name).value(:string, max_size?: 30)
        required(:age).value(:integer, gt?: 18)
        required(:tags).maybe(:array)

        optional(:country).hash do
          required(:name).filled(:string)
          required(:code).filled(:string)
        end

        required(:people).array(:hash) do
          required(:name).filled(:string)
          required(:age).filled(:integer, gteq?: 18)
        end
      end

      rule(:my_business_rule, :age, :name) do
        return if values[:age] < 55 && values[:name] != "William"

        key(:age).failure(text: "William's must be less than 55", code: "WILLIAM_AGE_MUST_BE_LESS_THAN_55")
      end

    end

    it "returns error for string type validation" do
      contract = MyMockedContract.call(name: 123)

      default_errors = contract.errors.to_h
      en_errors = contract.errors(locale: :en).to_h
      es_errors = contract.errors(locale: :es).to_h
      pt_br_errors = contract.errors(locale: :"pt-BR").to_h

      error_i18n_key = "contract.errors.str?"
      expect(default_errors[:name]).to eq([I18n.t(error_i18n_key, locale: :en)])
      expect(en_errors[:name]).to eq([I18n.t(error_i18n_key, locale: :en)])
      expect(es_errors[:name]).to eq([I18n.t(error_i18n_key, locale: :es)])
      expect(pt_br_errors[:name]).to eq([I18n.t(error_i18n_key, locale: :"pt-BR")])
    end

    it "returns error for string min length validation" do
      contract = MyMockedContract.call(name: "a")

      default_errors = contract.errors.to_h
      en_errors = contract.errors(locale: :en).to_h
      es_errors = contract.errors(locale: :es).to_h
      pt_br_errors = contract.errors(locale: :"pt-BR").to_h

      error_i18n_key = "contract.errors.size?.value.string.arg.range"
      expect(default_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :en, size_left: 2, size_right: 30)])
      expect(en_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :en, size_left: 2, size_right: 30)])
      expect(es_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :es, size_left: 2, size_right: 30)])
      expect(pt_br_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :"pt-BR", size_left: 2, size_right: 30)])
    end

    it "returns error for string max length validation" do
      contract = MyMockedContract.call(name: "a" * 31)

      default_errors = contract.errors.to_h
      en_errors = contract.errors(locale: :en).to_h
      es_errors = contract.errors(locale: :es).to_h
      pt_br_errors = contract.errors(locale: :"pt-BR").to_h

      error_i18n_key = "contract.errors.size?.value.string.arg.range"
      expect(default_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :en, size_left: 2, size_right: 30)])
      expect(en_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :en, size_left: 2, size_right: 30)])
      expect(es_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :es, size_left: 2, size_right: 30)])
      expect(pt_br_errors[:name])
        .to eq([I18n.t(error_i18n_key, locale: :"pt-BR", size_left: 2, size_right: 30)])
    end

    it "returns error for number greather than validation" do
      contract = MyMockedContract.call(age: 17)

      default_errors = contract.errors.to_h
      en_errors = contract.errors(locale: :en).to_h
      es_errors = contract.errors(locale: :es).to_h
      pt_br_errors = contract.errors(locale: :"pt-BR").to_h

      error_i18n_key = "contract.errors.gt?"
      expect(default_errors[:age]).to eq([I18n.t(error_i18n_key, locale: :en, num: 18)])
      expect(en_errors[:age]).to eq([I18n.t(error_i18n_key, locale: :en, num: 18)])
      expect(es_errors[:age]).to eq([I18n.t(error_i18n_key, locale: :es, num: 18)])
      expect(pt_br_errors[:age]).to eq([I18n.t(error_i18n_key, locale: :"pt-BR", num: 18)])
    end

    it "allows optional fields" do
      contract = MyMockedContract.call({})
      default_errors = contract.errors.to_h
      expect(default_errors[:last_name]).to eq nil

      contract = MyMockedContract.call(last_name: "l" * 31)
      default_errors = contract.errors.to_h
      expect(default_errors[:last_name]).to eq([I18n.t("contract.errors.max_size?", locale: :en, num: 30)])
    end

    it "allows empty" do
      contract = MyMockedContract.call(tags: "")
      default_errors = contract.errors.to_h
      expect(default_errors[:tags]).to eq nil
    end

    it "allows nested hash and allows to validate it" do
      contract = MyMockedContract.call({})
      default_errors = contract.errors.to_h
      expect(default_errors[:country]).to eq nil

      contract = MyMockedContract.call(country: {})
      default_errors = contract.errors.to_h
      expect(default_errors[:country]).to eq(name: ["is missing"], code: ["is missing"])
    end

    it "allows nested array" do
      contract = MyMockedContract.call({})
      default_errors = contract.errors.to_h
      expect(default_errors[:people]).to eq ["is missing"]

      contract = MyMockedContract.call(people: [])
      default_errors = contract.errors.to_h
      expect(default_errors[:people]).to eq nil

      contract = MyMockedContract.call(people: [{}])
      default_errors = contract.errors.to_h
      expect(default_errors[:people]).to eq(0 => { name: ["is missing"], age: ["is missing"] })
    end

    it "validates business rule" do
      contract = MyMockedContract.call(age: 60, name: "William")

      default_errors = contract.errors.to_h
      en_errors = contract.errors(locale: :en).to_h
      es_errors = contract.errors(locale: :es).to_h
      pt_br_errors = contract.errors(locale: :"pt-BR").to_h

      expected_error = [{ code: "WILLIAM_AGE_MUST_BE_LESS_THAN_55", text: "William's must be less than 55" }]

      expect(default_errors[:age]).to eq(expected_error)
      expect(en_errors[:age]).to eq(expected_error)
      expect(es_errors[:age]).to eq(expected_error)
      expect(pt_br_errors[:age]).to eq(expected_error)
    end
  end
end
