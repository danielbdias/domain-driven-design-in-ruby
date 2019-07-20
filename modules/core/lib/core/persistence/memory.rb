require "securerandom"
require "will_paginate/array"

class Core::Persistence::Memory < Core::Persistence::Abstract

  class QueryError < StandardError; end

  # Memory persistence implementation to use with Core::Repository.
  # To see all interface methods look at the Core::Repository implementation.
  #
  # You have to set entity_class property as your Entity class.
  #
  # Example
  #
  #   class SubscriptionRepository < Core::Repository
  #
  #     self.persistence = Core::Persistence::Memory
  #     self.persistence_scope = :company_id
  #     self.entity_class = MyEntity
  #
  #   end
  #   repo = SubscriptionRepository.new(1)
  #   repo.create({name: "RDStation"})

  def initialize(entity_class:, identifier_field: nil, **)
    super
    @entity_class = entity_class
    @identifier_field = identifier_field || :id
  end

  attr_reader :entity_class, :identifier_field

  def self.transaction
    yield
  end

  def self.transaction_rollback; end

  def create(data)
    attributes = get_attributes_from_data(data)
    add_scope_to_attributes(attributes)

    entity = entity_class.new(attributes)
    entity.id ||= SecureRandom.uuid

    all.push(entity)
    entity
  end

  def update(id, data)
    attributes = get_attributes_from_data(data)

    entity = find_in_records!(id)
    entity.assign_attributes(attributes)
    entity
  rescue QueryError
    ::Core::Persistence::QueryError.new(error: "Couldn't find record with 'id'=#{id}")
  end

  def delete(id)
    record = find_in_records!(id)
    records.delete(record)
  rescue QueryError
    ::Core::Persistence::QueryError.new(error: "Couldn't find record with 'id'=#{id}")
  end

  def soft_delete(id)
    delete(id)
  end

  def delete_all
    return @records[scope_value] = [] if @records && scope && @records[scope_value]

    @records = nil
  end

  def soft_delete_all
    delete_all
  end

  def all
    records
  end

  def paginate(page:, page_size:)
    all.paginate(page: page, per_page: page_size)
  end

  def find(id)
    find_in_records(id)
  end

  def find_by(attributes)
    all.find do |record|
      attributes.all? do |key, value|
        record.send(key) == value
      end
    end
  end

  def first
    all.first
  end

  def last
    all.last
  end

  def count
    all.size
  end

  private

  def records
    return scoped_records if scope

    non_scoped_records
  end

  def scoped_records
    return @records[scope_value] if @records && scope && @records[scope_value]

    @records ||= {}
    @records[scope_value] ||= []
  end

  def non_scoped_records
    return @records if @records

    @records = []
  end

  def add_scope_to_attributes(attributes)
    return attributes unless scope
    attributes[scope] = scope_value
  end

  def get_attributes_from_data(data)
    # Data could be eather an entity or attributes
    data.is_a?(Hash) ? data : data.attributes
  end

  def find_in_records(id)
    records.find { |entity| entity.send(identifier_field) == id }
  end

  def find_in_records!(id)
    record = find_in_records(id)
    return record if record

    raise QueryError
  end

end
