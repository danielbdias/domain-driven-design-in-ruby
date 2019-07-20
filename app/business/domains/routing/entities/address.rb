class Domains::Routing::Entities::Address < Core::Entity

  attribute :id, Types::Integer
  attribute :name, Types::String
  attribute :number, Types::Integer.optional
  attribute :complement, Types::String.optional
  attribute :zip_code, Types::String.constrained(format: /[0-9]+/, min_size: 8, max_size: 8)
  attribute :city, Types::String
  attribute :state, Types::String.constrained(included_in: BRAZILIAN_STATES)
  attribute :kind, Types::String.constrained(included_in: ADDRESS_KIND)

  private

  ADDRESS_KIND = [
    'home',
    'work',
    'other'
  ]

  BRAZILIAN_STATES = [
    'Acre',
    'Alagoas',
    'Amapá',
    'Amazonas',
    'Bahia',
    'Ceará',
    'Distrito Federal',
    'Espírito Santo',
    'Goiás',
    'Maranhão',
    'Mato Grosso',
    'Mato Grosso do Sul',
    'Minas Gerais',
    'Pará ',
    'Paraíba',
    'Paraná',
    'Pernambuco',
    'Piauí',
    'Rio de Janeiro',
    'Rio Grande do Norte',
    'Rio Grande do Sul',
    'Rondônia',
    'Roraima',
    'Santa Catarina',
    'São Paulo',
    'Sergipe',
    'Tocantins'
  ]
end
