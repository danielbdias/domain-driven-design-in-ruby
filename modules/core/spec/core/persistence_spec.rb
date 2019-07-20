require "spec_helper"

RSpec.describe Core::Persistence do
  describe Core::Persistence::PersistenceError do
    it "exists" do
      error = Core::Persistence::PersistenceError.new(
        errors: { a: [:taken] },
        entity: "myfakeentity",
        persistence_object: "myfakemodel"
      )
      expect(error.errors).to eq(a: [:taken])
      expect(error.entity).to eq("myfakeentity")
      expect(error.persistence_object).to eq("myfakemodel")
    end
  end

  describe Core::Persistence::QueryError do
    it "exists" do
      error = Core::Persistence::QueryError.new(error: "myfakeerror")
      expect(error.error).to eq("myfakeerror")
    end
  end
end
