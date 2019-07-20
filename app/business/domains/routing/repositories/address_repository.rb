class Domains::Routing::Repositories::AddressRepository < Core::Repository

  self.persistence = Domains::Routing::Persistence.current
  self.persistence_identifier_field = :id
  self.persistence_model = Domains::Routing::Repositories::Models::Address
  self.entity_class = Domains::Routing::Entities::Address

  def convert_persistence_object_to_entity(persistence_object)
    persistence_attributes = persistence_object.attributes

    entity_attributes = {
      "id" => persistence_object.id,
      "name" => persistence_object.name,
      "number" => persistence_object.number,
      "complement" => persistence_object.complement,
      "zip_code" => persistence_object.zip_code,
      "city" => persistence_object.city,
      "state" => persistence_object.state,
      "kind" => persistence_object.kind
    }

    entity_class.new(persistence_attributes.merge(entity_attributes))
  end

  def convert_entity_attrs_to_persistence_object_attrs(entity)
    entity.attributes
  end

end
