class Domains::Routing::Repositories::GPSRepository

  def find_by_type(type)
    model = Domains::Routing::Repositories::Models::GPS.find_by(gps_type: type)
    Domains::Routing::Entities::GPS.new(id: model.id, type: model.gps_type)
  end

  def create(entity)
    Domains::Routing::Repositories::Models::GPS.create(gps_type: entity.type)
  end

end
