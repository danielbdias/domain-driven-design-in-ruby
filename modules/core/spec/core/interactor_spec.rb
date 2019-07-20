require "spec_helper"

RSpec.describe Core::Interactor do
  def mock_active_record_transaction
    Object.const_get(:ActiveRecord).const_set(:Base, Class.new do
      def self.transaction
        yield
      rescue ActiveRecord::Rollback
      end
    end)
  end

  def undo_mock_active_record_transaction
    Object.const_get(:ActiveRecord).send(:remove_const, :Base)
  end

  context "when inherits from Core::Interactor" do
    class MockedInteractor < Core::Interactor

      expose :a

      step :one

      def one(input)
        return Success(input) if input[:a]
        Failure(input)
      end

    end

    it "do not allow to instanciate" do
      expect { MockedInteractor.new.call(a: 123) }.to raise_exception(NoMethodError)
    end

    it "wraps successful response and convert to response object" do
      response = MockedInteractor.call(a: 123)
      expect(response.success?).to eq true
      expect(response.content).to eq(a: 123)
      expect(response).to be_kind_of(Core::Response)
    end

    it "wraps successful response and exposes only exposed attributes" do
      response = MockedInteractor.call(a: 123, b: 321, c: "abc")
      expect(response.success?).to eq true
      expect(response.content).to eq(a: 123)
      expect(response).to be_kind_of(Core::Response)
    end

    it "wraps failure response and convert to response object" do
      response = MockedInteractor.call(b: 123)
      expect(response.failure?).to eq true
      expect(response.content).to eq(b: 123)
      expect(response).to be_kind_of(Core::Response)
    end

    context "when interactor does not expose attributes" do
      class MockedInteractorWithoutExpose < Core::Interactor

        step :one

        def one(input)
          Success(input)
        end

      end

      it "raises on call" do
        expect do
          MockedInteractorWithoutExpose.call({})
        end.to raise_error("You need to define the attributes that will be exposed.")
      end
    end

    context "when last step does not include exposed attributes" do
      class MockedInteractorWithExpose < Core::Interactor

        expose :invoice, :subscription

        step :one

        def one(input)
          Success(input)
        end

      end

      it "raises on call for missing attribute :invoice" do
        expect do
          MockedInteractorWithExpose.call({})
        end.to raise_error("You need to set the following attributes at your steps: [:invoice, :subscription]")
      end

      it "raises on call for missing attribute :subscription" do
        expect do
          MockedInteractorWithExpose.call(invoice: "fake")
        end.to raise_error("You need to set the following attributes at your steps: [:subscription]")
      end

      it "do not raises on call for not missing attributes" do
        response = MockedInteractorWithExpose.call(invoice: "fake", subscription: "fake", a: 123)
        expect(response.success?).to eq true
        expect(response.content).to eq(invoice: "fake", subscription: "fake")
        expect(response).to be_kind_of(Core::Response)
      end
    end
  end

  context "when interactor does define repository without block" do
    class MockedInteractorWithoutRepoBlock < Core::Interactor

      expose :a

      repository :nota_fiscal_repository

      step :one

      def one(input)
        Success(input)
      end

    end

    it do
      expect do
        MockedInteractorWithoutRepoBlock.call({})
      end.to raise_error("You need to instanciate the repository nota_fiscal_repository.")
    end
  end

  context "when interactor does define repository but block is empty" do
    class MockedInteractorWithEmptyRepo < Core::Interactor

      expose :a

      repository :nota_fiscal_repository do
      end

      step :one

      def one(input)
        Success(input)
      end

    end

    it do
      expect do
        MockedInteractorWithEmptyRepo.call({})
      end.to raise_error("Repository nota_fiscal_repository is not an instance of Core::Repository.")
    end
  end

  context "when interactor does define repository but block is not a Core::Repository instance" do
    class MockedInteractorWithInvalidRepo < Core::Interactor

      expose :a

      repository :nota_fiscal_repository do
        "string"
      end

      step :one

      def one(input)
        Success(input)
      end

    end

    it do
      expect do
        MockedInteractorWithInvalidRepo.call({})
      end.to raise_error("Repository nota_fiscal_repository is not an instance of Core::Repository.")
    end
  end

  context "when interactor does define repository but name is invalid" do
    class MockedRepo < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord

    end

    class MockedInteractorWithInvalidRepoName < Core::Interactor

      expose :a

      repository :nota_fiscal do
        MockedRepo.new
      end

      step :one

      def one(input)
        Success(input)
      end

    end

    it "enforces repository name convention" do
      expect do
        MockedInteractorWithInvalidRepoName.call({})
      end.to raise_error("Repository named nota_fiscal needs to have _repository suffix.")
    end
  end

  context "when interactor define repository to an active record repository" do
    class MockedARRepo < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord

    end

    class MockedInteractorWithActiveRecordRepository < Core::Interactor

      expose :a

      repository :nota_fiscal_repository do
        MockedARRepo.new
      end

      step :one

      def one(input)
        return Success(input) if input[:a]
        Failure(input)
      end

    end

    before do
      mock_active_record_transaction
    end

    after do
      undo_mock_active_record_transaction
    end

    it "wraps response inside active record transaction" do
      expect(Core::Persistence::ActiveRecord).to receive(:transaction).and_call_original

      response = MockedInteractorWithActiveRecordRepository.call(a: 123, b: 321, c: "abc")
      expect(response.success?).to eq true
      expect(response.content).to eq(a: 123)
    end

    it "wraps response inside active record transaction and return failure" do
      expect(Core::Persistence::ActiveRecord).to receive(:transaction).and_call_original
      expect(Core::Persistence::ActiveRecord).to receive(:transaction_rollback).and_call_original

      response = MockedInteractorWithActiveRecordRepository.call(a: false, b: 321, c: "abc")
      expect(response.failure?).to eq true
      expect(response.content).to eq(a: false, b: 321, c: "abc")
    end
  end

  context "when interactor define repository to an active record repository with persistence scope" do
    class MockedScopedARRepo < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord
      self.persistence_scope = :company_id

    end

    class MockedInteractorWithScopedActiveRecordRepository < Core::Interactor

      expose :a

      repository :nota_fiscal_repository do |input|
        MockedScopedARRepo.new(input[:company_id])
      end

      step :one

      def one(input)
        return Success(input) if input[:a]
        Failure(input)
      end

    end

    before do
      mock_active_record_transaction
    end

    after do
      undo_mock_active_record_transaction
    end

    it "wraps response inside active record transaction" do
      expect(Core::Persistence::ActiveRecord).to receive(:transaction).and_call_original

      response = MockedInteractorWithScopedActiveRecordRepository.call(company_id: "xpto", a: 123, b: 321, c: "abc")
      content = response.content
      expect(response.success?).to eq true
      expect(content[:a]).to eq(123)
    end

    it "wraps response inside active record transaction and return failure" do
      expect(Core::Persistence::ActiveRecord).to receive(:transaction).and_call_original
      expect(Core::Persistence::ActiveRecord).to receive(:transaction_rollback).and_call_original

      response = MockedInteractorWithScopedActiveRecordRepository.call(company_id: "mycomp", a: false, b: 321, c: "abc")
      expect(response.failure?).to eq true
      expect(response.content).to eq(company_id: "mycomp", a: false, b: 321, c: "abc")
    end
  end

  context "when interactor define multiple reposoitories with different persistences" do
    class MockedARRepo < Core::Repository

      self.persistence = Core::Persistence::ActiveRecord

    end

    class MockPersistenceWithTransaction < Core::Persistence::Abstract

      def self.transaction
        yield
      end

      def self.transaction_rollback; end

    end

    class MockedTransactionRepo < Core::Repository

      self.persistence = MockPersistenceWithTransaction

    end

    class MockedInteractorWithPersistencesForMultipleTransactions < Core::Interactor

      expose :a

      repository :ar_repository do
        MockedARRepo.new
      end
      repository :other_repository do
        MockedTransactionRepo.new
      end

      step :one

      def one(input)
        return Success(input) if input[:a]
        Failure(input)
      end

    end

    before do
      mock_active_record_transaction
    end

    after do
      undo_mock_active_record_transaction
    end

    it "wraps response inside active record transaction" do
      expect(Core::Persistence::ActiveRecord).to receive(:transaction).and_call_original
      expect(MockPersistenceWithTransaction).to receive(:transaction).and_call_original

      response = MockedInteractorWithPersistencesForMultipleTransactions.call(a: 123, b: 321, c: "abc")
      expect(response.success?).to eq true
      expect(response.content).to eq(a: 123)
    end

    it "wraps response inside active record transaction and return failure" do
      expect(Core::Persistence::ActiveRecord).to receive(:transaction).and_call_original
      expect(Core::Persistence::ActiveRecord).to receive(:transaction_rollback).and_call_original
      expect(MockPersistenceWithTransaction).to receive(:transaction).and_call_original
      expect(MockPersistenceWithTransaction).to receive(:transaction_rollback).and_call_original

      response = MockedInteractorWithPersistencesForMultipleTransactions.call(a: false)
      expect(response.failure?).to eq true
      expect(response.content).to eq(a: false)
    end
  end

  context "when interactor uses repositories at steps" do
    class MockPersistenceOne < Core::Persistence::Abstract

      def self.transaction
        yield
      end

      def self.transaction_rollback; end

    end

    class MockPersistenceTwo < Core::Persistence::Abstract

      def self.transaction
        yield
      end

      def self.transaction_rollback; end

    end

    class MockedRepoOne < Core::Repository

      self.persistence = MockPersistenceOne
      self.persistence_scope = :company_id

    end

    class MockedRepoTwo < Core::Repository

      self.persistence = MockPersistenceTwo

    end

    class MockedInteractorWithStepsUsingRepos < Core::Interactor

      expose :company_id, :one_repository, :two_repository

      repository :one_repository do |input|
        MockedRepoOne.new(input[:company_id])
      end
      repository :two_repository do
        MockedRepoTwo.new
      end

      step :one

      def one(input)
        Success(input.merge(one_repository: one_repository, two_repository: two_repository))
      end

    end

    it "allows step to use defined methods for repositories and assigns right scope value to scoped repositories" do
      response = MockedInteractorWithStepsUsingRepos.call(company_id: 1234)
      content = response.content
      expect(response.success?).to eq true
      expect(content[:company_id]).to eq 1234

      one_repository = content[:one_repository]
      two_repository = content[:two_repository]
      expect(one_repository).to be_kind_of(MockedRepoOne)
      expect(one_repository.persistence_scope_value).to eq(1234)
      expect(two_repository).to be_kind_of(MockedRepoTwo)
    end
  end

  context "when interactor uses contract" do
    class MockedContract < Core::Contract

      params do
        required(:name).value(:string)
      end

    end

    class MockedInteractorWithContract < Core::Interactor

      expose :name

      contract MockedContract

      step :one

      def one(input)
        Success(input)
      end

    end

    it "validates input with contract and assign errors to output" do
      response = MockedInteractorWithContract.call(name: nil)
      expect(response.failure?).to eq true
      expect(response.content).to eq(name: nil, errors: { name: ["must be a string"] })
    end

    it "validates input with contract and assign translated errors to output" do
      I18n.locale = :"pt-BR"

      response = MockedInteractorWithContract.call(name: nil)
      expect(response.failure?).to eq true
      expect(response.content).to eq(name: nil, errors: { name: ["deve ser uma string"] })

      I18n.locale = :en
    end

    it "does not return errors when is valid" do
      response = MockedInteractorWithContract.call(name: "my valid name")
      expect(response.success?).to eq true
      expect(response.content).to eq(name: "my valid name")
    end
  end

  context "when interactor uses multiple contracts" do
    class MockedContractOne < Core::Contract

      params do
        optional(:name).value(:string)
      end

    end

    class MockedCustomerContract < Core::Contract

      params do
        required(:customer).hash do
          required(:name).filled(:string)
        end
      end

    end

    class MockedInteractorWithMultipleContracts < Core::Interactor

      expose :name

      contract MockedContractOne
      step :set_customer
      contract MockedCustomerContract

      def set_customer(input)
        Success(input.merge(customer: { name: input[:name] }))
      end

    end

    it "validates input with multiple contracts and assign errors to output" do
      response = MockedInteractorWithMultipleContracts.call(name: "")
      expect(response.failure?).to eq true
      expect(response.content)
        .to eq(name: "", customer: { name: "" }, errors: { customer: { name: ["must be filled"] } })
    end

    it "validates input with contract and assign translated errors to output" do
      I18n.locale = :"pt-BR"

      response = MockedInteractorWithMultipleContracts.call(name: "")
      expect(response.failure?).to eq true
      expect(response.content)
        .to eq(name: "", customer: { name: "" }, errors: { customer: { name: ["deve estar preenchido"] } })

      I18n.locale = :en
    end

    it "does not return errors when is valid" do
      response = MockedInteractorWithContract.call(name: "my valid name")
      expect(response.success?).to eq true
      expect(response.content).to eq(name: "my valid name")
    end
  end
end
