module Core::Persistence

  class PersistenceError

    def initialize(errors:, entity: nil, persistence_object: nil)
      @errors = errors
      @entity = entity
      @persistence_object = persistence_object
    end

    attr_reader :errors, :entity, :persistence_object

  end

  class QueryError

    def initialize(error:)
      @error = error
    end

    attr_reader :error

  end

end
