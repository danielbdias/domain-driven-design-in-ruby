require "spec_helper"

RSpec.describe Core::Persistence::Memory do
  class MockedEntityForMemoryTests < Core::Entity

    attribute :id, Types::Strict::Integer
    attribute :public_id, Types::Strict::String
    attribute :company_id, Types::Strict::Integer
    attribute :number, Types::Strict::String

  end

  let(:persistence) do
    Core::Persistence::Memory.new(scope: :company, scope_value: 2, entity_class: MockedEntityForMemoryTests)
  end

  it "requires entity_class" do
    expect { Core::Persistence::Memory.new }.to raise_error("missing keyword: entity_class")
  end

  it "sets scope and scope_value to nil as default" do
    persistence = Core::Persistence::Memory.new(entity_class: MockedEntityForMemoryTests)
    expect(persistence.scope).to eq nil
    expect(persistence.scope_value).to eq nil
  end

  it "allows to set scope and scope_value" do
    persistence = Core::Persistence::Memory.new(
      scope: :company_id, scope_value: 6, entity_class: MockedEntityForMemoryTests
    )
    expect(persistence.scope).to eq :company_id
    expect(persistence.scope_value).to eq 6
  end

  it "allows to set entity_class" do
    persistence = Core::Persistence::Memory.new(entity_class: MockedEntityForMemoryTests)
    expect(persistence.entity_class).to eq MockedEntityForMemoryTests
  end

  describe ".transaction" do
    it "wraps response" do
      result = Core::Persistence::Memory.transaction do
        1 + 1
      end
      expect(result).to eq 2
    end
  end

  describe ".transaction_rollback" do
    it "do not raises" do
      expect { Core::Persistence::Memory.transaction_rollback }.not_to raise_exception
    end
  end

  context "when implements Core::Persistence::Memory as persistence layer for Core::Repository" do
    class MockedMemoryRepository < Core::Repository

      self.persistence = Core::Persistence::Memory
      self.entity_class = MockedEntityForMemoryTests

    end

    class MockedMemoryRepositoryWithScope < Core::Repository

      self.persistence = Core::Persistence::Memory
      self.persistence_scope = :company_id
      self.entity_class = MockedEntityForMemoryTests

    end

    class MockedMemoryRepositoryWithIdField < Core::Repository

      self.persistence = Core::Persistence::Memory
      self.persistence_identifier_field = :public_id
      self.entity_class = MockedEntityForMemoryTests

    end

    let(:repo) { MockedMemoryRepository.new }
    let(:company_id) { 10 }
    let(:repo_with_company_id) { MockedMemoryRepositoryWithScope.new(company_id) }

    describe "#create" do
      it "adds entity to in memory list and returns entity" do
        entity = repo.create(id: 1, number: "123", company_id: company_id)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "123"
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq entity.id
      end

      it "accepts entity instead of attributes" do
        entity = MockedEntityForMemoryTests.new(id: 1, number: "123", company_id: company_id)

        entity = repo.create(entity)
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq entity.id
      end

      it "generates id when not informed for attributes" do
        entity = repo.create(number: "123", company_id: company_id)
        expect(entity.id).not_to eq nil
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).not_to eq nil
      end

      it "generates id when not informed for entity" do
        entity = MockedEntityForMemoryTests.new(number: "123", company_id: company_id)

        entity = repo.create(entity)
        expect(entity.id).not_to eq nil
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).not_to eq nil
      end

      it "persists scope to AR create" do
        entity = MockedEntityForMemoryTests.new(id: 1, number: "123")

        entity = repo_with_company_id.create(entity)
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)
      end

      it "adds to scoped list" do
        repo_with_company_id = MockedMemoryRepositoryWithScope.new(10)
        repo_with_another_company_id = MockedMemoryRepositoryWithScope.new(535)

        repo_with_company_id.create(id: 1, number: "123", company_id: company_id)
        repo_with_another_company_id.create(id: 3, number: "123", company_id: company_id)

        list = repo_with_company_id.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 1

        list = repo_with_another_company_id.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 3
      end
    end

    describe "#update" do
      it "replaces entity at in memory list and returns entity" do
        repo.create(id: 1, number: "123", company_id: company_id)

        entity = repo.update(1, number: "432", company_id: company_id)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "432"
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq entity.id
        expect(list.first.number).to eq "432"
      end

      it "accepts entity instead of attributes" do
        repo.create(id: 1, number: "123", company_id: company_id)

        entity_for_update = MockedEntityForMemoryTests.new(id: 1, number: "432", company_id: company_id)
        entity = repo.update(1, entity_for_update)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "432"
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq entity.id
        expect(list.first.number).to eq "432"
      end

      it "changes scoped records only" do
        repo_with_another_company_id = MockedMemoryRepositoryWithScope.new(535)

        repo_with_company_id.create(id: 1, number: "123", company_id: company_id)
        repo_with_another_company_id.create(id: 3, number: "123", company_id: company_id)

        query_error = repo_with_company_id.update(3, number: "432", company_id: company_id)
        expect(query_error).to be_kind_of(::Core::Persistence::QueryError)
        expect(query_error.error).to eq("Couldn't find record with 'id'=3")

        entity = repo_with_company_id.update(1, number: "432", company_id: company_id)
        expect(entity.id).to eq 1
        expect(entity.company_id).to eq company_id
        expect(entity.number).to eq "432"
        expect(entity).to be_kind_of(MockedEntityForMemoryTests)

        list = repo_with_company_id.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq entity.id
        expect(list.first.number).to eq "432"
      end

      it "returns query error when record with given id does not exists" do
        query_error = repo.update(13, {})
        expect(query_error).to be_kind_of(::Core::Persistence::QueryError)
        expect(query_error.error).to eq("Couldn't find record with 'id'=13")
      end
    end

    describe "#delete" do
      it "deletes record with given id" do
        repo.create(id: 51, number: "123", company_id: company_id)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 51
        repo.delete(51)
        expect(repo.all.size).to eq 0
      end

      it "deletes record with given id for specific scope" do
        repo_with_company_id = MockedMemoryRepositoryWithScope.new(10)
        repo_with_another_company_id = MockedMemoryRepositoryWithScope.new(535)

        repo_with_company_id.create(id: 1, number: "123", company_id: company_id)
        repo_with_another_company_id.create(id: 3, number: "123", company_id: company_id)

        list = repo_with_company_id.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 1
        repo_with_company_id.delete(1)
        expect(repo_with_company_id.all.size).to eq 0

        list = repo_with_another_company_id.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 3
        repo_with_another_company_id.delete(3)
        expect(repo_with_another_company_id.all.size).to eq 0
      end

      it "returns query error when record with given id does not exists" do
        query_error = repo.delete(13)
        expect(query_error).to be_kind_of(::Core::Persistence::QueryError)
        expect(query_error.error).to eq("Couldn't find record with 'id'=13")
      end
    end

    describe "#soft_delete" do
      it "deletes record with given id" do
        repo.create(id: 51, number: "123", company_id: company_id)

        list = repo.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 51
        repo.soft_delete(51)
        expect(repo.all.size).to eq 0
      end

      it "deletes record with given id for specific scope" do
        repo_with_company_id = MockedMemoryRepositoryWithScope.new(10)
        repo_with_another_company_id = MockedMemoryRepositoryWithScope.new(535)

        repo_with_company_id.create(id: 1, number: "123", company_id: company_id)
        repo_with_another_company_id.create(id: 3, number: "123", company_id: company_id)

        list = repo_with_company_id.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 1
        repo_with_company_id.soft_delete(1)
        expect(repo_with_company_id.all.size).to eq 0

        list = repo_with_another_company_id.all
        expect(list.size).to eq 1
        expect(list.first.id).to eq 3
        repo_with_another_company_id.soft_delete(3)
        expect(repo_with_another_company_id.all.size).to eq 0
      end

      it "returns query error when record with given id does not exists" do
        query_error = repo.soft_delete(13)
        expect(query_error).to be_kind_of(::Core::Persistence::QueryError)
        expect(query_error.error).to eq("Couldn't find record with 'id'=13")
      end
    end

    describe "#delete_all" do
      it "clears all records" do
        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)

        expect(repo.all.size).to eq 2
        repo.delete_all
        expect(repo.all.size).to eq 0
      end

      it "clears all records for specific scope" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "123", company_id: company_id)

        repo.persistence.scope_value = 10
        expect(repo.all.size).to eq 2
        repo.delete_all
        expect(repo.all.size).to eq 0

        repo.persistence.scope_value = 15
        expect(repo.all.size).to eq 1
        repo.delete_all
        expect(repo.all.size).to eq 0
      end
    end

    describe "#soft_delete_all" do
      it "clears all records" do
        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)

        expect(repo.all.size).to eq 2
        repo.soft_delete_all
        expect(repo.all.size).to eq 0
      end

      it "clears all records for specific scope" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "123", company_id: company_id)

        repo.persistence.scope_value = 10
        expect(repo.all.size).to eq 2
        repo.soft_delete_all
        expect(repo.all.size).to eq 0

        repo.persistence.scope_value = 15
        expect(repo.all.size).to eq 1
        repo.soft_delete_all
        expect(repo.all.size).to eq 0
      end
    end

    describe "#all" do
      it "returns all entities" do
        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "321", company_id: company_id)

        entities = repo.all

        first = entities.first
        expect(first.id).to eq 1
        expect(first.number).to eq "123"
        expect(first.company_id).to eq company_id

        second = entities.last
        expect(second.id).to eq 2
        expect(second.number).to eq "321"
        expect(second.company_id).to eq company_id
      end

      it "applies persistence scope to AR all" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: 10)
        repo.create(id: 2, number: "321", company_id: 10)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "321", company_id: 15)

        repo.persistence.scope_value = 10
        entities = repo.all
        expect(entities.size).to eq 2

        first = entities.first
        expect(first.id).to eq 1
        expect(first.number).to eq "123"
        expect(first.company_id).to eq 10

        second = entities.last
        expect(second.id).to eq 2
        expect(second.number).to eq "321"
        expect(second.company_id).to eq 10

        repo.persistence.scope_value = 15
        entities = repo.all
        expect(entities.size).to eq 1

        first = entities.first
        expect(first.id).to eq 3
        expect(first.number).to eq "321"
        expect(first.company_id).to eq 15
      end
    end

    describe "#paginate" do
      it "returns paginated entities" do
        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "321", company_id: company_id)

        # Page 1 Page size
        entities = repo.paginate(page: 1, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 1

        # Page 2 Page size 1
        entities = repo.paginate(page: 2, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 2

        # Page 1 Page size 2
        entities = repo.paginate(page: 1, page_size: 2)
        expect(entities.size).to eq 2
        expect(entities.first.id).to eq 1
        expect(entities.last.id).to eq 2
      end

      it "applies persistence scope to AR all" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: 10)
        repo.create(id: 2, number: "321", company_id: 10)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "321", company_id: 15)

        ## Scope value 10

        repo.persistence.scope_value = 10
        # Page 1 Page size
        entities = repo.paginate(page: 1, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 1

        # Page 2 Page size 1
        entities = repo.paginate(page: 2, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 2

        # Page 1 Page size 2
        entities = repo.paginate(page: 1, page_size: 2)
        expect(entities.size).to eq 2
        expect(entities.first.id).to eq 1
        expect(entities.last.id).to eq 2

        ## Scope value 15

        repo.persistence.scope_value = 15
        # Page 1 Page size
        entities = repo.paginate(page: 1, page_size: 1)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 3

        # Page 2 Page size 1
        entities = repo.paginate(page: 2, page_size: 1)
        expect(entities.size).to eq 0

        # Page 1 Page size 2
        entities = repo.paginate(page: 1, page_size: 2)
        expect(entities.size).to eq 1
        expect(entities.first.id).to eq 3
      end
    end

    describe "#find" do
      it "returns record with id" do
        repo.create(id: 1, number: "123", company_id: company_id)

        entity = repo.find(1)
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
      end

      it "return nil when not found" do
        expect(repo.find(4)).to eq nil
      end

      it "applies persistence scope to AR find" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "321", company_id: company_id)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "321", company_id: company_id)

        repo.persistence.scope_value = 10
        expect(repo.find(2).id).to eq 2

        repo.persistence.scope_value = 15
        expect(repo.find(3).id).to eq 3
      end

      it "find entity with another id field" do
        repo = MockedMemoryRepositoryWithIdField.new

        repo.create(id: 1, public_id: "xpto", number: "123", company_id: company_id)

        entity = repo.find("xpto")
        expect(entity.id).to eq 1
        expect(entity.number).to eq "123"
        expect(entity.company_id).to eq company_id
      end
    end

    describe "#find_by" do
      it "returns found record" do
        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "321", company_id: company_id)

        entity = repo.find_by(number: "123")
        expect(entity.id).to eq 1

        entity = repo.find_by(number: "321")
        expect(entity.id).to eq 2

        entity = repo.find_by(number: "321", company_id: company_id)
        expect(entity.id).to eq 2

        entity = repo.find_by(number: "321", company_id: "another")
        expect(entity).to eq nil
      end

      it "return nil when not found" do
        expect(repo.find_by(number: "abc")).to eq nil
      end

      it "applies persistence scope to AR first" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "321", company_id: company_id)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "321", company_id: company_id)

        repo.persistence.scope_value = 10
        expect(repo.find_by(number: "321").id).to eq 2

        repo.persistence.scope_value = 15
        expect(repo.find_by(number: "321").id).to eq 3
      end
    end

    describe "#first" do
      it "returns first record" do
        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)
        repo.create(id: 3, number: "123", company_id: company_id)
        expect(repo.first.id).to eq 1

        repo.create(id: 7, number: "432", company_id: company_id)
        first = repo.first
        expect(first.id).to eq 1
        expect(first.number).to eq "123"
      end

      it "return nil when list is empty" do
        expect(repo.first).to eq nil
      end

      it "applies persistence scope to AR first" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "123", company_id: company_id)

        repo.persistence.scope_value = 10
        expect(repo.first.id).to eq 1

        repo.persistence.scope_value = 15
        expect(repo.first.id).to eq 3
      end
    end

    describe "#last" do
      it "returns last record" do
        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)
        repo.create(id: 3, number: "123", company_id: company_id)
        expect(repo.last.id).to eq 3

        repo.create(id: 7, number: "432", company_id: company_id)
        last = repo.last
        expect(last.id).to eq 7
        expect(last.number).to eq "432"

        repo.create(id: 4, number: "321", company_id: company_id)
        last = repo.last
        expect(last.id).to eq 4
        expect(last.number).to eq "321"
      end

      it "return nil when list is empty" do
        expect(repo.last).to eq nil
      end

      it "applies persistence scope to AR last" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "123", company_id: company_id)

        repo.persistence.scope_value = 10
        expect(repo.last.id).to eq 2

        repo.persistence.scope_value = 15
        expect(repo.last.id).to eq 3
      end
    end

    describe "#count" do
      it "returns records count" do
        expect(repo.count).to eq 0

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)
        repo.create(id: 3, number: "123", company_id: company_id)
        expect(repo.count).to eq 3
      end

      it "applies persistence scope to AR count" do
        repo = MockedMemoryRepositoryWithScope.new(10)

        repo.create(id: 1, number: "123", company_id: company_id)
        repo.create(id: 2, number: "123", company_id: company_id)

        repo.persistence.scope_value = 15
        repo.create(id: 3, number: "123", company_id: company_id)

        repo.persistence.scope_value = 10
        expect(repo.count).to eq 2

        repo.persistence.scope_value = 15
        expect(repo.count).to eq 1
      end
    end
  end
end
