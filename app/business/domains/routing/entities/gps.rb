class Domains::Routing::Entities::GPS < Core::Entity

  attribute :id, Types::Integer
  attribute :type, Types::String

  def calculate(origin, destination)
    maps_client = case self.type
                  when "troll"
                    Domains::Routing::Clients::TrollMaps.new
                  else
                    Domains::Routing::Clients::GoogleMaps.new
                  end

    maps_client.calculate_route(origin, destination)
  end

end
