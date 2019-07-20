class Domains::Routing::Repositories::GPSRepository < Core::Repository

  self.persistence = Domains::Routing::Persistence.current
  self.persistence_identifier_field = :id
  self.persistence_model = Domains::Routing::Repositories::Models::GPS
  self.entity_class = Domains::Routing::Entities::GPS

  def convert_persistence_object_to_entity(persistence_object)
    persistence_attributes = persistence_object.attributes

    entity_attributes = {
      "id" => persistence_object.id,
      "type" => persistence_object.type
    }

    entity_class.new(persistence_attributes.merge(entity_attributes))
  end

  def convert_entity_attrs_to_persistence_object_attrs(entity)
    entity.attributes
  end

end
