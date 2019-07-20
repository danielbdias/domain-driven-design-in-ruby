require "active_model"
require "active_record/errors"

class Core::Persistence::ActiveRecord < Core::Persistence::Abstract

  class QueryError < StandardError; end

  # ActiveRecord persistence implementation to use with Core::Repository.
  # To see all interface methods look at the Core::Repository implementation.
  #
  # You have to set persistence_model property as your AR Model class.
  # You have to define convert_persistence_object_to_entity methods.
  #
  # As a pattern, query methods (AR scopes) should be defined at repository not at data layer.
  #
  # Example
  #
  #   class SubscriptionRepository < Core::Repository
  #
  #     self.persistence = Core::Persistence::ActiveRecord
  #     self.persistence_scope = :company_id
  #     self.persistence_model = MyModel
  #
  #     def convert_entity_to_model_object
  #
  #     end
  #
  #     def convert_model_object_to_entity
  #
  #     end
  #
  #   end
  #   repo = SubscriptionRepository.new(1)
  #   repo.create({name: "RDStation"})

  def initialize(model:, identifier_field: nil,
                 convert_persistence_object_to_entity:,
                 convert_entity_attrs_to_persistence_object_attrs:, **)
    super
    @model = model
    @identifier_field = identifier_field || :id
    @convert_persistence_object_to_entity = convert_persistence_object_to_entity
    @convert_entity_attrs_to_persistence_object_attrs = convert_entity_attrs_to_persistence_object_attrs
  end

  attr_reader :model, :identifier_field

  def self.transaction
    ActiveRecord::Base.transaction do
      yield
    end
  end

  def self.transaction_rollback
    raise ActiveRecord::Rollback
  end

  def create(data)
    attributes = get_attributes_from_data(data)
    add_scope_to_attributes(attributes)

    persistence_object = model.create(attributes)
    entity = convert_persistence_object_to_entity(persistence_object)

    error_messages = persistence_object.errors.messages
    raise ::ActiveRecord::Rollback if error_messages.any?
    entity
  rescue ::ActiveRecord::Rollback
    ::Core::Persistence::PersistenceError.new(
      errors: error_messages,
      entity: entity,
      persistence_object: persistence_object
    )
  end

  def update(id, data)
    attributes = get_attributes_from_data(data)

    persistence_object = find_persistence_object!(id)
    persistence_object.update(attributes)
    entity = convert_persistence_object_to_entity(persistence_object)

    error_messages = persistence_object.errors.messages
    raise ::ActiveRecord::Rollback if error_messages.any?
    entity
  rescue ::ActiveRecord::Rollback
    ::Core::Persistence::PersistenceError.new(
      errors: error_messages,
      entity: entity,
      persistence_object: persistence_object
    )
  rescue QueryError
    ::Core::Persistence::QueryError.new(error: "Couldn't find record with 'id'=#{id}")
  end

  def delete(id)
    persistence_object = find_persistence_object!(id)
    return true if persistence_object.delete
    false
  rescue QueryError
    ::Core::Persistence::QueryError.new(error: "Couldn't find record with 'id'=#{id}")
  end

  def soft_delete(id)
    persistence_object = find_persistence_object!(id)
    return true if persistence_object.destroy
    false
  rescue QueryError
    ::Core::Persistence::QueryError.new(error: "Couldn't find record with 'id'=#{id}")
  end

  def delete_all
    scoped_model.delete_all
  end

  def soft_delete_all
    scoped_model.find_each(&:destroy)
    true
  end

  def all
    persistence_objects = scoped_model.all
    convert_persistence_objects_to_entity(persistence_objects)
  end

  def paginate(page:, page_size:)
    persistence_objects = scoped_model.paginate(page: page, per_page: page_size)
    convert_persistence_objects_to_entity(persistence_objects)
  end

  def find(id)
    find_by(identifier_field => id)
  end

  def find_by(attributes)
    persistence_object = scoped_model.find_by(attributes)
    convert_persistence_object_to_entity(persistence_object) if persistence_object
  end

  def first
    persistence_object = scoped_model.first
    convert_persistence_object_to_entity(persistence_object) if persistence_object
  end

  def last
    persistence_object = scoped_model.last
    convert_persistence_object_to_entity(persistence_object) if persistence_object
  end

  def count
    scoped_model.count
  end

  def convert_persistence_object_to_entity(persistence_object)
    @convert_persistence_object_to_entity.call(persistence_object)
  end

  def convert_entity_attrs_to_persistence_object_attrs(entity)
    @convert_entity_attrs_to_persistence_object_attrs.call(entity)
  end

  private

  def add_scope_to_attributes(attributes)
    return attributes unless scope
    attributes[scope] = scope_value
  end

  def get_attributes_from_data(data)
    return data if data.is_a?(Hash)

    convert_entity_attrs_to_persistence_object_attrs(data)
  end

  def scoped_model
    return model unless scope
    model.where(scope => scope_value)
  end

  def find_persistence_object!(id)
    persistence_object = scoped_model.find_by(identifier_field => id)
    return persistence_object if persistence_object
    raise QueryError
  end

  def convert_persistence_objects_to_entity(persistence_objects)
    persistence_objects.map do |persistence_object|
      convert_persistence_object_to_entity(persistence_object)
    end
  end

end
