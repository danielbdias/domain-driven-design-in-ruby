class Domains::Routing::ValueObjects::Route < Core::ValueObject

  attribute :origin, Types.Instance(Domains::Routing::Entities::Address)
  attribute :destination, Types.Instance(Domains::Routing::Entities::Address)
  attribute :instructions, Types::Array.of(Types.Instance(Domains::Routing::ValueObjects::RouteInstruction))

  def print_route
    puts "Origin: #{origin}"
    puts "Destination: #{destination}"
    puts "Instructions:"
    for instruction in instructions do
      puts instruction.to_s
    end
  end

end
