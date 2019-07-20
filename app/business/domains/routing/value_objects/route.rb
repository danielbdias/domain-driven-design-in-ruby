class Domains::Routing::ValueObjects::Route < Core::ValueObject

  attribute :origin, Types.Instance(Domains::Routing::Entities::Address)
  attribute :destination, Types.Instance(Domains::Routing::Entities::Address)
  attribute :instructions, Types::Array.of(Types.Instance(Domains::Routing::ValueObjects::RouteInstruction))

end
