class Domains::Routing::Contracts::TraceRoute < Core::Contract

  params do
    required(:attributes).hash do
      required(:origin_id).filled(:integer)
      required(:destination_id).filled(:integer)
      required(:gps_type).filled(:integer)
    end
  end

end
