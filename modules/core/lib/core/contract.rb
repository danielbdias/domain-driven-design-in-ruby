class Core::Contract < Dry::Validation::Contract

  # Extend from Core::Contract to implement a new contract.
  # Contracts are based on dry-validation. For full documentation access: https://dry-rb.org/gems/dry-validation/
  # Contract params are based on dry-schema. For full documentation access: https://dry-rb.org/gems/dry-schema/params/
  #
  # Format and type validations stay at params block, other business rules needs to be declared with rule blocks.
  # To see all built in validations access: https://dry-rb.org/gems/dry-schema/basics/built-in-predicates/
  #
  # You need to add i18n file to your contract if you want custom translated error messages. You can do it with:
  # config.messages.load_paths << File.expand_path("../../config/locales/contracts.yml", __dir__)
  #
  # Each domain should have a Parent Contract class doing this load. Like that:
  #
  # class Domains::Taxes::Contract < Core::Contract
  #   config.messages.load_paths << File.expand_path("../../config/locales/contracts.yml", __dir__)
  # end
  #
  # class MyTaxesContract < Domains::Taxes::Contract
  #   # ...
  # end
  #
  # Example
  #
  #   class MyContract < Core::Contract
  #     params do
  #       # To see all built in validations access: https://dry-rb.org/gems/dry-schema/basics/built-in-predicates/
  #       required(:name).value(:string, size?: 2..30)
  #       optional(:last_name).value(:string, max_size?: 30)
  #       required(:age).value(:integer, gt?: 18)
  #       required(:tags).maybe(:array)
  #
  #       # To see all options to declare nested params access: https://dry-rb.org/gems/dry-schema/nested-data/
  #       optional(:country).hash do
  #         required(:name).filled(:string)
  #         required(:code).filled(:string)
  #       end
  #
  #       required(:people).array(:hash) do
  #         required(:name).filled(:string)
  #         required(:age).filled(:integer, gteq?: 18)
  #       end
  #     end
  #
  #     rule(:my_business_rule, :age, :name) do
  #       return if values[:age] < 55 && values[:name] != "William"
  #       key(:age).failure(text: "William's must be less than 55", code: "WILLIAM_AGE_MUST_BE_LESS_THAN_55")
  #     end
  #
  #     rule(:my_business_rule_with_i18n, :age, :name) do
  #       return if values[:age] < 55 && values[:name] != "William"
  #       key(:age).failure(text: :my_business_rule_with_i18n, code: "WILLIAM_AGE_MUST_BE_LESS_THAN_55")
  #     end
  #
  #     # Rule that does not depend on any fields
  #     # Error key will be base instead field name
  #     rule(:creating_is_allowed_only_on_weekdays) do
  #       if today.saturday? || today.sunday?
  #         base.failure("creating is allowed only on weekdays")
  #       end
  #     end
  #   end
  #
  # Example of defining validations
  #
  # en:
  #   contract:
  #     errors:
  #       common_validation: 'must be 123'
  #       rules:
  #         age:
  #           invalid: 'must be greater than 18'
  # pt-BR:
  #   contract:
  #     errors:
  #       common_validation: 'deve ser 123'
  #       rules:
  #         age:
  #           invalid: 'deve ser maior que 18'

  # dry-validations #config
  # https://www.rubydoc.info/gems/dry-validation/Dry/Validation/Contract#config-instance_method

  # the key in the locale files under which messages are defined
  config.messages.top_namespace = :contract

  # # the localization backend to use. Supported values are: :yaml and :i18n
  config.messages.backend = :i18n

  # # an array of files paths that are used to load messages
  config.messages.load_paths << File.expand_path("../../config/locales/contract.yml", __dir__)

  # # default I18n-compatible locale identifier
  config.messages.default_locale = :en

  private_class_method :new

  class << self

    # Name is used just to give a name to the rule and show it explicitly
    def rule(_name = nil, *keys, &block)
      super(*keys, &block)
    end

    def call(*args)
      new.call(*args)
    end

  end

end
