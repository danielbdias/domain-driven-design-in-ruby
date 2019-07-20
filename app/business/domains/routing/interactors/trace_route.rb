class Domains::Routing::Interactors::TraceRoute

  def execute(origin_id:, destination_id:, gps_type:)
    address_repository = Domains::Routing::Repositories::AddressRepository.new
    gps_repository = Domains::Routing::Repositories::GPSRepository.new

    origin = address_repository.find(origin_id)
    destination = address_repository.find(destination_id)

    gps = gps_repository.find_by_type(gps_type)

    gps.calculate(origin, destination)
  end

end
