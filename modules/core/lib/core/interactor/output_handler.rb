class Core::Interactor
  class OutputHandler

    attr_reader :output, :exposed_attributes

    def initialize(output, exposed_attributes)
      @output = output
      @exposed_attributes = exposed_attributes
    end

    def handle
      validate_output_exposed_attributes
      convert_output_to_response_object
    end

    private

    def validate_output_exposed_attributes
      return if output.failure?

      result = output.value!
      unset_exposed_atributes = exposed_attributes.reject { |attribute| result.include?(attribute) }

      return if unset_exposed_atributes.empty?

      raise AttributeExpositionError,
            "You need to set the following attributes at your steps: #{unset_exposed_atributes}"
    end

    def convert_output_to_response_object
      return Core::Response.failure(output.failure) unless output.success?

      content = output.value!.slice(*exposed_attributes)
      Core::Response.success(content)
    end

  end
end
