module Domains::Routing

  module_function

  def trace_route(attributes)
    Domains::Routing::Interactors::TraceRoute.call(attributes)
  end

end
