class Core::Interactor
  class PersistenceTransactionHandler

    def initialize(repos)
      @repos = repos

      return unless @repos
      set_persistences_for_transaction_from_repos
    end

    def handle
      # Defining a first lambda to be called nested in a lambda three wrapper by all persistences transactions
      persistence_transaction = -> { yield }

      # Iterating over all persistences to wrap a transaction around the iteractor excecution
      # In case of multile transactions one will be wrapped inside other and
      # iteractor excecution will happen at the last level
      @persistences_for_transaction&.each do |persistence_for_transaction|
        persistence_transaction = wrap_call_inside_persistence_transaction(persistence_for_transaction,
                                                                           persistence_transaction)
      end

      persistence_transaction.call
    end

    private

    def set_persistences_for_transaction_from_repos
      return if @repos.empty?

      @persistences_for_transaction = @repos.map do |_repo_name, repo_instance|
        repo_instance.persistence.class
      end.uniq
    end

    # Wraps a single persistence transaction and handle fallbacks in case of failure
    def wrap_call_inside_persistence_transaction(persistence, execution)
      lambda do
        result = nil
        persistence.transaction do
          result = execution.call
          persistence.transaction_rollback if result.failure?
        end
        result
      end
    end

  end
end
