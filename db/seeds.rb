gps_repository = Domains::Routing::Repositories::GPSRepository.new

troll_maps_gps = Domains::Routing::Entities::GPS.new(type: "troll")
gmaps_gps = Domains::Routing::Entities::GPS.new(type: "gmaps")

gps_repository.create(troll_maps_gps)
gps_repository.create(gmaps_gps)

address_repository = Domains::Routing::Repositories::AddressRepository.new

first_address = Domains::Routing::Entities::Address.new(name: "Rua Gomes de Carvalho",
                                                        number: 1666,
                                                        complement: "Bloco 2",
                                                        zip_code: "04547006",
                                                        city: "Sao Paulo",
                                                        state: "Sao Paulo",
                                                        kind: "work")

second_address = Domains::Routing::Entities::Address.new(name: "Rod. Virgilio Varzea",
                                                         zip_code: "88032000",
                                                         city: "Florianopolis",
                                                         state: "Santa Catarina",
                                                         kind: "work")

address_repository.create(first_address)
address_repository.create(second_address)
