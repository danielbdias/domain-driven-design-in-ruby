class Domains::Routing::Repositories::Models < ActiveRecord::Base

  self.abstract_class = true
  establish_connection(ENV.fetch("DATABASE_URL"))

end
