class Domains::Routing::Interactors::TraceRoute < Core::Interactor

  repository :address_repository do
    Domains::Routing::Repositories::AddressRepository.new
  end

  repository :gps_repository do
    Domains::Routing::Repositories::GPSRepository.new
  end

  contract Domains::Routing::Contracts::TraceRoute
  step :trace_route
  expose :route

  def trace_route(attributes:, **)
    origin = address_repository.find(attributes[:origin_id])
    destination = address_repository.find(attributes[:destination_id])

    gps = gps_repository.find_by(type: attributes[:gps_type])

    route = gps.calculate(origin, destination)

    Success(route: route)
  end

end
