module Core::Interactor::StepAdapters
  class Contract

    Dry::Transaction::StepAdapters.register :contract, new

    include Dry::Monads::Result::Mixin

    def call(operation, _options, args)
      result = operation.call(*args)
      errors = result.errors(locale: I18n.locale).to_h

      return Failure(args[0].merge(errors: errors)) if errors.any?

      Success(*args)
    end

  end
end
