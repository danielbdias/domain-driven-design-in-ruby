class Core::Response

  # Core::Response objects will be returned from Interactors and Bounded Contexts.
  #
  # Example
  #
  # response = Core::Response.success(invoices: [])
  # response.success?
  # => true
  # response.content
  # => { invoices: [] }
  #
  # response = Core::Response.failure(errors: { field: [] })
  # response.failure?
  # => true
  # response.content
  # => { errors: { field: [] } }

  class << self

    def success(content = nil)
      new(:success, content)
    end

    def failure(content = nil)
      new(:failure, content)
    end

  end

  attr_reader :status, :content

  # Warning if the status is not _:success_ or _:failure_ the status check will not work correctly
  # @example:
  #
  #  respose = Core::Response.new :success, 'content'
  #  response.success? # => true
  #  response.failure? # => false
  def initialize(status, content = nil)
    @status = status
    @content = content
  end

  def success?
    @status == :success
  end

  def failure?
    @status == :failure
  end

  # Allow the hash-like behavior to be compatible with the old response structure
  #
  # @example
  #
  #  UseCaseResponse.success('response content')[:status] # => :ok
  def [](method_name)
    send(method_name) if respond_to?(method_name)
  end

  # Extracts the nested value specified by the sequence of index objects by calling dig at each step,
  # returning nil if any intermediate step is nil.
  def dig(*args)
    result = self[args.shift]
    return result if args.empty?

    result&.dig(*args)
  end

end
