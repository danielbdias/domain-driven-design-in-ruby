require "spec_helper"
require "active_model"

RSpec.describe Core::Persistence::ActiveRecord do
  class MockedModelForARTests

    include ActiveModel::Model
    attr_accessor :id, :public_id, :company_id, :number

    def self.find(_id); end

    def self.where(_fields); end

    def self.find_each; end

    def self.count; end

    def self.first; end

    def self.last; end

    def self.find_by(_fields); end

    def self.all; end

    def self.paginate(page: nil, per_page: nil); end

    def self.create(_attrs); end

    def update(attrs)
      assign_attributes(attrs)
    end

    def delete; end

    def destroy; end

    def self.delete_all; end

    def attributes
      { id: id, company_id: company_id, number: number }
    end

  end

  let(:persistence) do
    Core::Persistence::ActiveRecord.new(
      scope: :company,
      scope_value: 2,
      model: MockedModelForARTests,
      convert_persistence_object_to_entity: -> {},
      convert_entity_attrs_to_persistence_object_attrs: -> {}
    )
  end

  it "sets scope and scope_value to nil as default" do
    persistence = Core::Persistence::ActiveRecord.new(
      model: MockedModelForARTests,
      convert_persistence_object_to_entity: -> {},
      convert_entity_attrs_to_persistence_object_attrs: -> {}
    )
    expect(persistence.scope).to eq nil
    expect(persistence.scope_value).to eq nil
  end

  it "allows to set scope and scope_value" do
    persistence = Core::Persistence::ActiveRecord.new(
      scope: :company_id,
      scope_value: 6,
      model: MockedModelForARTests,
      convert_persistence_object_to_entity: -> {},
      convert_entity_attrs_to_persistence_object_attrs: -> {}
    )
    expect(persistence.scope).to eq :company_id
    expect(persistence.scope_value).to eq 6
  end

  it "allows to set model" do
    persistence = Core::Persistence::ActiveRecord.new(
      model: "my model",
      convert_persistence_object_to_entity: -> {},
      convert_entity_attrs_to_persistence_object_attrs: -> {}
    )
    expect(persistence.model).to eq "my model"
  end

  it "allows to set convert_persistence_object_to_entity and convert_entity_attrs_to_persistence_object_attrs" do
    persistence = Core::Persistence::ActiveRecord.new(
      model: MockedModelForARTests,
      convert_persistence_object_to_entity: lambda { |x|
        x * 2
      },
      convert_entity_attrs_to_persistence_object_attrs: lambda { |x|
        x + 2
      }
    )
    expect(persistence.convert_persistence_object_to_entity(3)).to eq 6
    expect(persistence.convert_entity_attrs_to_persistence_object_attrs(3)).to eq 5
  end

  describe ".transaction" do
    before do
      Object.const_get(:ActiveRecord).const_set(:Base, Class.new do
        def self.transaction
          yield
        end
      end)
    end

    after do
      Object.const_get(:ActiveRecord).send(:remove_const, :Base)
    end

    it "wraps response inside active record transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).and_call_original

      result = Core::Persistence::ActiveRecord.transaction do
        1 + 2
      end
      expect(result).to eq 3
    end
  end

  describe ".transaction_rollback" do
    it "raises ActiveRecord::Rollback" do
      expect { Core::Persistence::ActiveRecord.transaction_rollback }.to raise_exception(ActiveRecord::Rollback)
    end
  end

  context "when implements Core::Persistence::ActiveRecord as persistence layer for Core::Repository" do
    class MockedEntityForARTests < Core::Entity

      attribute :id, Types::Strict::Integer
      attribute :public_id, Types::Strict::String
      attribute :company_id, Types::Strict::Integer
      attribute :number, Types::Strict::String

    end

    class MockedActiveRecordRepository < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord
      self.persistence_model = MockedModelForARTests
      self.entity_class = MockedEntityForARTests

    end

    class MockedActiveRecordRepositoryWithScope < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord
      self.persistence_scope = :company_id
      self.persistence_model = MockedModelForARTests
      self.entity_class = MockedEntityForARTests

    end

    class MockedActiveRecordRepositoryWithAnotherIdField < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord
      self.persistence_model = MockedModelForARTests
      self.persistence_identifier_field = :public_id
      self.entity_class = MockedEntityForARTests

    end

    let(:repo) { MockedActiveRecordRepository.new }
    let(:company_id) { 10 }
    let(:repo_with_company_id) { MockedActiveRecordRepositoryWithScope.new(company_id) }

    describe "#create" do
      it "delegates create to AR model and returns entity" do
        model_object = MockedModelForARTests.new(id: 1, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:create).and_return(model_object)

        entity = repo.create(id: 1, number: "123", company_id: company_id)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "123"
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "delegates create to AR and returns persistence error" do
        model_object = MockedModelForARTests.new(id: 1, number: "123", company_id: company_id)
        model_object.errors.add(:id, "already_taken")

        expect(MockedModelForARTests).to receive(:create).and_return(model_object)

        persistence_error = repo.create(id: 1, number: "123", company_id: company_id)
        entity = persistence_error.entity
        expect(persistence_error).to be_kind_of(::Core::Persistence::PersistenceError)
        expect(persistence_error.errors).to eq(id: ["already_taken"])
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "accepts entity instead of attributes" do
        entity = MockedEntityForARTests.new(id: 1, number: "123", company_id: company_id)

        model_object = MockedModelForARTests.new(id: 1, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:create).and_return(model_object)

        entity = repo.create(entity)
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "persists scope to AR create" do
        entity = MockedEntityForARTests.new(id: 1, number: "123")

        model_object = MockedModelForARTests.new(id: 1, number: "123", company_id: company_id)
        expect(MockedModelForARTests)
          .to receive(:create)
          .with(id: 1, number: "123", company_id: company_id)
          .and_return(model_object)

        entity = repo_with_company_id.create(entity)
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end
    end

    describe "#update" do
      it "delegates update to AR model and returns entity" do
        model_object = MockedModelForARTests.new(id: 1, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 1).and_return(model_object)
        expect(model_object).to receive(:update).and_call_original

        entity = repo.update(1, id: 1, number: "432", company_id: company_id)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "432"
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "delegates update to AR and returns persistence error" do
        model_object = MockedModelForARTests.new(id: 1, number: "123", company_id: company_id)
        model_object.errors.add(:id, "already_taken")

        expect(MockedModelForARTests).to receive(:find_by).with(id: 1).and_return(model_object)
        expect(model_object).to receive(:update).and_call_original

        persistence_error = repo.update(1, number: "123", company_id: company_id)
        entity = persistence_error.entity
        expect(persistence_error).to be_kind_of(::Core::Persistence::PersistenceError)
        expect(persistence_error.errors).to eq(id: ["already_taken"])
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "accepts entity instead of attributes" do
        entity = MockedEntityForARTests.new(id: 3, number: "321", company_id: company_id)

        model_object = MockedModelForARTests.new(id: 3, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 3).and_return(model_object)
        expect(model_object).to receive(:update).and_call_original

        entity = repo.update(3, entity)
        expect(entity.id).to eq 3
        expect(entity.number).to eq "321"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "accepts entity without id instead of attributes" do
        entity = MockedEntityForARTests.new(number: "321", company_id: company_id)

        model_object = MockedModelForARTests.new(id: 5, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 5).and_return(model_object)
        expect(model_object).to receive(:update).and_call_original

        entity = repo.update(5, entity)
        expect(entity.id).to eq 5
        expect(entity.number).to eq "321"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "returns query error when id does not exists" do
        entity = MockedEntityForARTests.new(number: "321", company_id: company_id)

        expect(MockedModelForARTests).to receive(:find_by).with(id: 5).and_return(nil)

        query_error = repo.update(5, entity)
        expect(query_error).to be_kind_of(::Core::Persistence::QueryError)
        expect(query_error.error).to eq("Couldn't find record with 'id'=5")
      end

      it "applies persistence scope to AR find" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(where_double).to receive(:find_by).with(id: 4).and_return(model_object)
        expect(model_object).to receive(:update).and_call_original

        entity = repo_with_company_id.update(4, id: 1, number: "432", company_id: company_id)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "432"
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "updates entity with another id field" do
        repo = MockedActiveRecordRepositoryWithAnotherIdField.new

        model_object = MockedModelForARTests.new(id: 1, public_id: "abc", number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(public_id: "abc").and_return(model_object)
        expect(model_object).to receive(:update).and_call_original

        entity = repo.update("abc", id: 1, number: "432", company_id: company_id)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "432"
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end
    end

    describe "#delete" do
      it "delegates delete to AR model and returns true" do
        model_object = MockedModelForARTests.new(id: 1, public_id: "abc", number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 1).and_return(model_object)
        expect(model_object).to receive(:delete).and_return(model_object)

        expect(repo.delete(1)).to eq true
      end

      it "returns query error when not found" do
        expect(MockedModelForARTests).to receive(:find_by).with(id: 3).and_return(nil)

        query_error = repo.delete(3)
        expect(query_error).to be_kind_of(::Core::Persistence::QueryError)
        expect(query_error.error).to eq("Couldn't find record with 'id'=3")
      end

      it "returns false when AR returns false" do
        model_object = MockedModelForARTests.new(id: 1, public_id: "abc", number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 1).and_return(model_object)
        expect(model_object).to receive(:delete).and_return(false)

        expect(repo.delete(1)).to eq false
      end

      it "applies persistence scope to AR delete" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        model_object = MockedModelForARTests.new(id: 4, public_id: "abc", number: "123", company_id: company_id)
        expect(where_double).to receive(:find_by).with(id: 4).and_return(model_object)
        expect(model_object).to receive(:delete).and_return(model_object)

        expect(repo_with_company_id.delete(4)).to eq true
      end
    end

    describe "#soft_delete" do
      it "delegates destroy to AR model and returns true" do
        model_object = MockedModelForARTests.new(id: 1, public_id: "abc", number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 1).and_return(model_object)
        expect(model_object).to receive(:destroy).and_return(model_object)

        expect(repo.soft_delete(1)).to eq true
      end

      it "returns query error when not found" do
        expect(MockedModelForARTests).to receive(:find_by).with(id: 3).and_return(nil)

        query_error = repo.soft_delete(3)
        expect(query_error).to be_kind_of(::Core::Persistence::QueryError)
        expect(query_error.error).to eq("Couldn't find record with 'id'=3")
      end

      it "returns false when AR returns false" do
        model_object = MockedModelForARTests.new(id: 1, public_id: "abc", number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 1).and_return(model_object)
        expect(model_object).to receive(:destroy).and_return(false)

        expect(repo.soft_delete(1)).to eq false
      end

      it "applies persistence scope to AR destroy" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        model_object = MockedModelForARTests.new(id: 4, public_id: "abc", number: "123", company_id: company_id)
        expect(where_double).to receive(:find_by).with(id: 4).and_return(model_object)
        expect(model_object).to receive(:destroy).and_return(model_object)

        expect(repo_with_company_id.soft_delete(4)).to eq true
      end
    end

    describe "#delete_all" do
      it "delegates delete_all to AR model and returns count" do
        expect(MockedModelForARTests).to receive(:delete_all).and_return(32)
        expect(repo.delete_all).to eq 32
      end

      it "applies persistence scope to AR delete_all" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        expect(where_double).to receive(:delete_all).and_return(12)
        expect(repo_with_company_id.delete_all).to eq 12
      end
    end

    describe "#soft_delete_all" do
      it "delegates destroy to AR model and returns true" do
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)

        expect(MockedModelForARTests).to receive(:find_each).and_yield(model_object)
        expect(model_object).to receive(:destroy).and_return(true)

        expect(repo.soft_delete_all).to eq true
      end

      it "applies persistence scope to AR find_each" do
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)

        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        expect(where_double).to receive(:find_each).and_yield(model_object)
        expect(model_object).to receive(:destroy).and_return(true)

        expect(repo_with_company_id.soft_delete_all).to eq true
      end
    end

    describe "#all" do
      it "returns all entities" do
        first = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        second = MockedModelForARTests.new(id: 6, number: "321", company_id: company_id)
        expect(MockedModelForARTests).to receive(:all).and_return([first, second])

        entities = repo.all

        first = entities.first
        expect(first.id).to eq 4
        expect(first.number).to eq "123"
        expect(first.company_id).to eq company_id
        expect(first).to be_kind_of(MockedEntityForARTests)

        second = entities.last
        expect(second.id).to eq 6
        expect(second.number).to eq "321"
        expect(second.company_id).to eq company_id
        expect(second).to be_kind_of(MockedEntityForARTests)
      end

      it "applies persistence scope to AR all" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        first = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        second = MockedModelForARTests.new(id: 6, number: "321", company_id: company_id)
        expect(where_double).to receive(:all).and_return([first, second])

        entities = repo_with_company_id.all

        first = entities.first
        expect(first.id).to eq 4
        expect(first.number).to eq "123"
        expect(first.company_id).to eq company_id
        expect(first).to be_kind_of(MockedEntityForARTests)

        second = entities.last
        expect(second.id).to eq 6
        expect(second.number).to eq "321"
        expect(second.company_id).to eq company_id
        expect(second).to be_kind_of(MockedEntityForARTests)
      end
    end

    describe "#paginate" do
      it "returns paginated entities" do
        first = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        second = MockedModelForARTests.new(id: 6, number: "321", company_id: company_id)

        # Page 1 Page size
        expect(MockedModelForARTests).to receive(:paginate).with(page: 1, per_page: 1).and_return([first])
        entities = repo.paginate(page: 1, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 4

        # Page 2 Page size 1
        expect(MockedModelForARTests).to receive(:paginate).with(page: 2, per_page: 1).and_return([second])
        entities = repo.paginate(page: 2, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 6

        # Page 1 Page size 2
        expect(MockedModelForARTests).to receive(:paginate).with(page: 1, per_page: 2).and_return([first, second])
        entities = repo.paginate(page: 1, page_size: 2)
        expect(entities.size).to eq 2
        expect(entities.first.id).to eq 4
        expect(entities.last.id).to eq 6
      end

      it "applies persistence scope to AR all" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).exactly(3).times.with(company_id: company_id).and_return(where_double)
        first = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        second = MockedModelForARTests.new(id: 6, number: "321", company_id: company_id)

        # Page 1 Page size
        expect(where_double).to receive(:paginate).with(page: 1, per_page: 1).and_return([first])
        entities = repo_with_company_id.paginate(page: 1, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 4

        # Page 2 Page size 1
        expect(where_double).to receive(:paginate).with(page: 2, per_page: 1).and_return([second])
        entities = repo_with_company_id.paginate(page: 2, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 6

        # Page 1 Page size 2
        expect(where_double).to receive(:paginate).with(page: 1, per_page: 2).and_return([first, second])
        entities = repo_with_company_id.paginate(page: 1, page_size: 2)
        expect(entities.size).to eq 2
        expect(entities.first.id).to eq 4
        expect(entities.last.id).to eq 6
      end
    end

    describe "#find" do
      it "returns record with id" do
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(id: 4).and_return(model_object)

        entity = repo.find(4)
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "return nil when not found" do
        expect(MockedModelForARTests).to receive(:find_by).with(id: 4).and_return(nil)
        expect(repo.find(4)).to eq nil
      end

      it "applies persistence scope to AR find" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        model_object = MockedModelForARTests.new(id: 5, number: "123", company_id: company_id)
        expect(where_double).to receive(:find_by).with(id: 5).and_return(model_object)

        entity = repo_with_company_id.find(5)
        expect(entity.id).to eq 5
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "find entity with another id field" do
        repo = MockedActiveRecordRepositoryWithAnotherIdField.new

        model_object = MockedModelForARTests.new(id: 4, public_id: "xpto", number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(public_id: "xpto").and_return(model_object)

        entity = repo.find("xpto")
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end
    end

    describe "#find_by" do
      it "returns found record" do
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:find_by).with(number: "123").and_return(model_object)

        entity = repo.find_by(number: "123")
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "return nil when not found" do
        expect(MockedModelForARTests).to receive(:find_by).with(number: "abc").and_return(nil)
        expect(repo.find_by(number: "abc")).to eq nil
      end

      it "applies persistence scope to AR find_by" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(where_double).to receive(:find_by).with(number: "123").and_return(model_object)

        entity = repo_with_company_id.find_by(number: "123")
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end
    end

    describe "#first" do
      it "returns first record" do
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:first).and_return(model_object)

        entity = repo.first
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "return nil when list is empty" do
        expect(MockedModelForARTests).to receive(:first).and_return(nil)
        expect(repo.first).to eq nil
      end

      it "applies persistence scope to AR first" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(where_double).to receive(:first).and_return(model_object)

        entity = repo_with_company_id.first
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end
    end

    describe "#last" do
      it "returns last record" do
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(MockedModelForARTests).to receive(:last).and_return(model_object)

        entity = repo.last
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end

      it "return nil when list is empty" do
        expect(MockedModelForARTests).to receive(:last).and_return(nil)
        expect(repo.last).to eq nil
      end

      it "applies persistence scope to AR last" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        model_object = MockedModelForARTests.new(id: 4, number: "123", company_id: company_id)
        expect(where_double).to receive(:last).and_return(model_object)

        entity = repo_with_company_id.last
        expect(entity.id).to eq 4
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForARTests)
      end
    end

    describe "#count" do
      it "returns records count" do
        expect(MockedModelForARTests).to receive(:count).and_return(1)
        expect(repo.count).to eq 1

        expect(MockedModelForARTests).to receive(:count).and_return(21)
        expect(repo.count).to eq 21
      end

      it "applies persistence scope to AR count" do
        where_double = double("where_double")
        expect(MockedModelForARTests).to receive(:where).with(company_id: company_id).and_return(where_double)
        expect(where_double).to receive(:count).and_return(12)
        expect(repo_with_company_id.count).to eq 12
      end
    end
  end
end
