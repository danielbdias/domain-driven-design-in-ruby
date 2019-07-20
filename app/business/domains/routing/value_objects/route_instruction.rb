class Domains::Routing::ValueObjects::RouteInstruction < Core::ValueObject

  attribute :description, Types::String
  attribute :order, Types::Integer

  def to_s
    "Passo #{order} - #{description}"
  end

end
