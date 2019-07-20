require "spec_helper"

RSpec.describe Core::Repository do
  context "when class inherits from Core::Repository and use ActiveRecord Persistence" do
    let(:repo) { MockedRepositoryAR.new }
    let(:persistence_class) { Core::Persistence::ActiveRecord }
    let(:persistence_instance) do
      Core::Persistence::ActiveRecord.new(
        model: "fake_model",
        convert_persistence_object_to_entity: -> {},
        convert_entity_attrs_to_persistence_object_attrs: -> {}
      )
    end

    class MockedRepositoryAR < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord

    end

    before do
      allow(persistence_class).to receive(:new).and_return(persistence_instance)
    end

    it "delegates create to persistence" do
      expect(persistence_instance).to receive(:create).with({})
      repo.create({})
    end

    it "delegates update to persistence" do
      expect(persistence_instance).to receive(:update).with(3, {})
      repo.update(3, {})
    end

    it "delegates delete to persistence" do
      expect(persistence_instance).to receive(:delete).with(31)
      repo.delete(31)
    end

    it "delegates soft_delete to persistence" do
      expect(persistence_instance).to receive(:soft_delete).with(12)
      repo.soft_delete(12)
    end

    it "delegates delete_all to persistence" do
      expect(persistence_instance).to receive(:delete_all)
      repo.delete_all
    end

    it "delegates soft_delete_all to persistence" do
      expect(persistence_instance).to receive(:soft_delete_all)
      repo.soft_delete_all
    end

    it "delegates all to persistence" do
      expect(persistence_instance).to receive(:all)
      repo.all
    end

    it "delegates paginate to persistence" do
      expect(persistence_instance).to receive(:paginate).with(page: 1, page_size: 5)
      repo.paginate(page: 1, page_size: 5)
    end

    it "delegates find to persistence" do
      expect(persistence_instance).to receive(:find).with(2)
      repo.find(2)
    end

    it "delegates find_by to persistence" do
      expect(persistence_instance).to receive(:find_by).with(public_id: 4)
      repo.find_by(public_id: 4)
    end

    it "delegates first to persistence" do
      expect(persistence_instance).to receive(:first)
      repo.first
    end

    it "delegates last to persistence" do
      expect(persistence_instance).to receive(:last)
      repo.last
    end

    it "delegates count to persistence" do
      expect(persistence_instance).to receive(:count)
      repo.count
    end
  end

  context "when class inherits from Core::Repository and use Memory Persistence" do
    let(:repo) { MockedRepositoryMemory.new }
    let(:persistence_class) { Core::Persistence::Memory }
    let(:persistence_instance) { Core::Persistence::Memory.new(entity_class: "myfakeentity") }

    class MockedRepositoryMemory < Core::Repository

      self.persistence = Core::Persistence::Memory

    end

    before do
      allow(persistence_class).to receive(:new).and_return(persistence_instance)
    end

    it "delegates create to persistence" do
      expect(persistence_instance).to receive(:create).with({})
      repo.create({})
    end

    it "delegates update to persistence" do
      expect(persistence_instance).to receive(:update).with(3, {})
      repo.update(3, {})
    end

    it "delegates delete to persistence" do
      expect(persistence_instance).to receive(:delete).with(31)
      repo.delete(31)
    end

    it "delegates soft_delete to persistence" do
      expect(persistence_instance).to receive(:soft_delete).with(12)
      repo.soft_delete(12)
    end

    it "delegates delete_all to persistence" do
      expect(persistence_instance).to receive(:delete_all)
      repo.delete_all
    end

    it "delegates soft_delete_all to persistence" do
      expect(persistence_instance).to receive(:soft_delete_all)
      repo.soft_delete_all
    end

    it "delegates all to persistence" do
      expect(persistence_instance).to receive(:all)
      repo.all
    end

    it "delegates paginate to persistence" do
      expect(persistence_instance).to receive(:paginate).with(page: 1, page_size: 5)
      repo.paginate(page: 1, page_size: 5)
    end

    it "delegates find to persistence" do
      expect(persistence_instance).to receive(:find).with(2)
      repo.find(2)
    end

    it "delegates find_by to persistence" do
      expect(persistence_instance).to receive(:find_by).with(public_id: 4)
      repo.find_by(public_id: 4)
    end

    it "delegates first to persistence" do
      expect(persistence_instance).to receive(:first)
      repo.first
    end

    it "delegates last to persistence" do
      expect(persistence_instance).to receive(:last)
      repo.last
    end

    it "delegates count to persistence" do
      expect(persistence_instance).to receive(:count)
      repo.count
    end
  end

  context "when class inherits from Core::Repository and sets persistence_scope" do
    let(:company_id) { 7 }
    let(:repo) { MockedRepositoryMemoryWithScope.new(company_id) }

    class MockedRepositoryMemoryWithScope < Core::Repository

      self.persistence = Core::Persistence::Memory
      self.persistence_scope = :company_id
      self.entity_class = "myfakeentity"

    end

    it "raises when scope is not informed" do
      expect { MockedRepositoryMemoryWithScope.new }.to raise_error("company_id scope need to be informed")
    end

    it "assigns persistence scope" do
      expect(repo.persistence_scope).to eq :company_id
      expect(repo.persistence_scope_value).to eq company_id
      expect(repo.persistence.scope).to eq :company_id
      expect(repo.persistence.scope_value).to eq company_id
    end
  end

  context "when class inherits from Core::Repository and sets persistence_model" do
    let(:repo) { MockedRepositoryActiveRecordWithModel.new }

    class MockedRepositoryActiveRecordWithModel < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord
      self.persistence_model = "myfakemodel"

    end

    it "assigns persistence model" do
      expect(repo.persistence_model).to eq "myfakemodel"
      expect(repo.persistence.model).to eq "myfakemodel"
    end
  end

  context "when class inherits from Core::Repository and sets convert persistence object methods" do
    let(:repo) { MockedRepositoryActiveRecordWithConvertPersistenceObjectMethods.new }

    class MockedRepositoryActiveRecordWithConvertPersistenceObjectMethods < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord

      def convert_persistence_object_to_entity(persistence_object)
        persistence_object * 5
      end

    end

    it "assigns lambda functions to persistence" do
      expect(repo.convert_persistence_object_to_entity(5)).to eq 25
      expect(repo.persistence.convert_persistence_object_to_entity(5)).to eq 25
    end
  end
end
