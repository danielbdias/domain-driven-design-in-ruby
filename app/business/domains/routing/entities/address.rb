class Domains::Routing::Entities::Address < Core::Entity

  attribute :id, Types::Integer
  attribute :name, Types::String
  attribute :number, Types::Integer.optional
  attribute :complement, Types::String.optional
  attribute :zip_code, Types::String.constrained(format: /[0-9]+/, min_size: 8, max_size: 8)
  attribute :city, Types::String
  attribute :state, Types::String
  attribute :kind, Types::String

end
