class Core::Entity < Dry::Struct

  # Extend from Core::Entity to implement a new entity.
  # Entities are based on dry-struct. For full documentation access: https://dry-rb.org/gems/dry-struct/
  #
  # Example
  #
  #   class MyFancyEntity < Core::Entity
  #     attribute :id, Types::Strict::Integer.optional
  #     attribute :number, Types::Strict::String
  #   end
  #   record = MyFancyEntity.new(id: nil, number: "123")
  #   record.id
  #   => nil
  #   record.number
  #   => '123'
  #
  #   # Constructor accepts string keys too
  #   record = MyFancyEntity.new("id" => 5, "number" => "4321")
  #   record.id
  #   => 5
  #   record.number
  #   => '4321'
  #
  #   # attributes method
  #   record.attributes
  #   => {id: 5, number: "4321"}

  transform_keys(&:to_sym)
  transform_types(&:omittable)

  def self.attribute(name, type = nil, &block)
    super
    define_attribute_setter(name)
  end

  def self.define_attribute_setter(name)
    define_method("#{name}=") do |value|
      attributes[name] = value
    end
  end

  def attributes=(new_attributes)
    @attributes = self.class.schema[new_attributes]
  end

  def assign_attributes(new_attributes)
    new_attributes.each do |key, value|
      attributes[key] = value
    end
  end

  module Types

    include Dry.Types

    DateTimeUtcZero = Types.Constructor(::DateTime) { |datetime| datetime.new_offset("+00:00") }
    UUID = Types::Strict::String.constrained(
      format: /\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\z/i
    )

  end

end
