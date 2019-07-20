require "spec_helper"

RSpec.describe Core::Persistence::Abstract do
  context "when inherits from Core::Persistence::Abstract" do
    let(:persistence) { Core::Persistence::Fake.new }

    class Core::Persistence::Fake < Core::Persistence::Abstract
    end

    it "sets scope and scope_value to nil as default" do
      persistence = Core::Persistence::Fake.new
      expect(persistence.scope).to eq nil
      expect(persistence.scope_value).to eq nil
    end

    it "allows to set scope and scope_value" do
      persistence = Core::Persistence::Fake.new(scope: :company_id, scope_value: 6)
      expect(persistence.scope).to eq :company_id
      expect(persistence.scope_value).to eq 6

      persistence.scope_value = 8
      expect(persistence.scope_value).to eq 8
    end

    it "needs to implement self.transaction" do
      expect do
        Core::Persistence::Fake.transaction { 1 + 1 }
      end
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented self.transaction")
    end

    it "needs to implement self.transaction_rollback" do
      expect do
        Core::Persistence::Fake.transaction_rollback { 1 + 1 }
      end
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented self.transaction_rollback")
    end

    it "needs to implement create" do
      expect { persistence.create({}) }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented create(data), data: {}")
    end

    it "needs to implement update" do
      expect { persistence.update(1, {}) }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented update(id, data), id: 1, data: {}")
    end

    it "needs to implement delete" do
      expect { persistence.delete(1) }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented delete(id), id: 1")
    end

    it "needs to implement soft_delete" do
      expect { persistence.soft_delete(1) }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented soft_delete(id), id: 1")
    end

    it "needs to implement delete_all" do
      expect { persistence.delete_all }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented delete_all")
    end

    it "needs to implement soft_delete_all" do
      expect { persistence.soft_delete_all }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented soft_delete_all")
    end

    it "needs to implement all" do
      expect { persistence.all }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented all")
    end

    it "needs to implement paginate" do
      expect { persistence.paginate(page: 1, page_size: 15) }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented paginate(page:, page_size:), page: 1, page_size: 15")
    end

    it "needs to implement find" do
      expect { persistence.find(12) }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented find(id), id: 12")
    end

    it "needs to implement find_by" do
      expect { persistence.find_by(public_id: 5) }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented find_by(attributes), attributes: {:public_id=>5}")
    end

    it "needs to implement first" do
      expect { persistence.first }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented first")
    end

    it "needs to implement last" do
      expect { persistence.last }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented last")
    end

    it "needs to implement count" do
      expect { persistence.count }
        .to raise_error("Core::Persistence::Fake -> " \
          "No Implemented count")
    end
  end
end
