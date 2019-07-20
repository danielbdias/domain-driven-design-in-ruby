module Domains::Routing

  module_function

  def trace_route(origin_id:, destination_id:, gps_type:)
    Domains::Routing::Interactors::TraceRoute.new.execute(origin_id: origin_id, destination_id: destination_id, gps_type: gps_type)
  end

end
