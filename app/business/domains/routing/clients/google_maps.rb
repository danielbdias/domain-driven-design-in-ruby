class Domains::Routing::Clients::GoogleMaps
  def calculate_route(origin, destination)
    instructions = [
      Domains::Routing::ValueObjects::RouteInstruction(order: 1, description: "Use o teletransporte a direita."),
      Domains::Routing::ValueObjects::RouteInstruction(order: 2, description: "Pronto !")
    ]

    Domains::Routing::ValueObjects::Route.new(origin, destination, instructions)
  end
end
