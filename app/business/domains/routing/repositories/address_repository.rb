class Domains::Routing::Repositories::AddressRepository

  def find(id)
    model = Domains::Routing::Repositories::Models::Address.find(id)

    Domains::Routing::Entities::Address.new(
      id: model.id,
      name: model.name,
      number: model.number,
      complement: model.complement,
      zip_code: model.zip_code,
      city: model.city,
      state: model.state,
      kind: model.kind
    )
  end

  def create(entity)
    Domains::Routing::Repositories::Models::Address.create(
      name: entity.name,
      number: entity.number,
      complement: entity.complement,
      zip_code: entity.zip_code,
      city: entity.city,
      state: entity.state,
      kind: entity.kind
    )
  end

end
