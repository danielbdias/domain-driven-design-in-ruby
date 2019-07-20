require "forwardable"

class Core::Interactor

  # Extend from Core::Interactor to implement a new interactor.
  # Interactors are based on dry-transaction. For full documentation access: https://dry-rb.org/gems/dry-transaction/
  #
  # If you use one or more repositories you can define it using the repository helper.
  # If you do so, it will automatically wraps all the steps inside a persistence transaction
  # and will rollback if a step fails
  #
  # You can use contracts to validate input. The contract can be declared before all steps or after a specific step.
  # Sometimes we need to fetch some data from repo before validate, the step to fetch the data can come before contract.
  #
  # Example
  #
  # class CreateNotaFiscal < Core::Interactor
  #   expose :nota_fiscal
  #
  #   repository :nota_fiscal_repository do |input|
  #     NotaFiscalRepository.new(input[:company_id])
  #   end
  #
  #   contract NotaFiscalContract
  #   step :create_nota_fiscal
  #
  #   def create_nota_fiscal(attributes:, **)
  #     nota_fiscal = nota_fiscal_repository.create(attributes)
  #     Success(nota_fiscal: nota_fiscal)
  #   end
  # end
  #
  # class UpdateNotaFiscal < Core::Interactor
  #   expose :nota_fiscal
  #
  #   repository :nota_fiscal_repository do |input|
  #     NotaFiscalRepository.new(input[:company_id])
  #   end
  #
  #   step :fetch_nota_fiscal
  #   contract NotaFiscalContract # Contract will be validated after fetch nota fiscal step
  #   step :update_nota_fiscal
  #
  #   def fetch_nota_fiscal(input)
  #     nota_fiscal = nota_fiscal_repository.find(input[:nota_fiscal_id])
  #     Success(input.merge(nota_fiscal: nota_fiscal))
  #   end
  #
  #   def update_nota_fiscal(input)
  #     # ...
  #   end
  # end

  class AttributeExpositionError < StandardError; end

  class InvalidRepository < StandardError; end

  include Dry::Transaction

  private_class_method :new

  class << self

    extend Forwardable

    attr_reader :exposed_attributes, :repo_blocks

    def_delegators :new, :call

    def expose(*attributes)
      @exposed_attributes = attributes
    end

    def repository(repo_name, &block)
      @repo_blocks ||= {}
      @repo_blocks[repo_name] = block
    end

  end

  def call(input)
    setup(input)

    output = PersistenceTransactionHandler.new(@repos).handle do
      super(input)
    end

    OutputHandler.new(output, exposed_attributes).handle
  end

  private

  # Overrided from dry-transaction to add ability to handle contracts
  # https://github.com/dry-rb/dry-transaction/blob/08617f7f564f4871670600665b225bdf8cd1be9d/lib/dry/transaction/instance_methods.rb#L84
  def resolve_operation(step, **operations)
    step_adapter = step.adapter
    step_adapter_class = step_adapter.adapter.owner

    if step_adapter_class == ::Core::Interactor::StepAdapters::Contract
      contract = step_adapter.options[:step_name]
      return contract
    end

    super
  end

  def exposed_attributes
    self.class.exposed_attributes
  end

  def repo_blocks
    self.class.repo_blocks
  end

  def setup(input)
    @input = input

    validate_exposed_attributes_presence

    return unless repo_blocks

    assign_repositories
  end

  def validate_exposed_attributes_presence
    return if exposed_attributes&.any?
    raise AttributeExpositionError, "You need to define the attributes that will be exposed."
  end

  def assign_repositories
    @repos = {}
    repo_blocks.each do |repo_name, repo_block|
      raise InvalidRepository, "You need to instanciate the repository #{repo_name}." unless repo_block
      repo = repo_block.call(@input)
      validate_repo(repo_name, repo)
      define_method_for_repo(repo_name, repo)
      @repos[repo_name] = repo
    end
  end

  def validate_repo(repo_name, repo)
    unless repo_name.to_s.end_with?("_repository")
      raise InvalidRepository, "Repository named #{repo_name} needs to have _repository suffix."
    end

    return if repo.class.ancestors.include?(::Core::Repository)
    raise InvalidRepository, "Repository #{repo_name} is not an instance of Core::Repository."
  end

  def define_method_for_repo(repo_name, repo)
    instance_variable_set("@#{repo_name}", repo)
    self.class.define_method(repo_name) do
      instance_variable_get("@#{repo_name}")
    end
  end

end
