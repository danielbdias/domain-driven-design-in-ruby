class Domains::Routing::Interactors::TraceRoute

  def initialize(address_repository: nil, gps_repository: nil)
    @address_repository = address_repository || Domains::Routing::Repositories::AddressRepository.new
    @gps_repository = gps_repository || Domains::Routing::Repositories::GPSRepository.new
  end

  def execute(origin_id:, destination_id:, gps_type:)
    origin = @address_repository.find(origin_id)
    destination = @address_repository.find(destination_id)

    gps = @gps_repository.find_by_type(gps_type)

    gps.calculate(origin, destination)
  end

end

