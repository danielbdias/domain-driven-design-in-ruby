require "forwardable"

class Core::Repository

  # Extend from Core::Repository to implement a new repository.
  # Repositories are inspired by hanami. https://guides.hanamirb.org/repositories/overview/
  # Along with repository, you have to define a persistence layer that can be Core::Persistence::ActiveRecord or Core::Persistence::Memory.
  # Check for implementation requisites in each persistence layer class.
  #
  # You can define a persistence_scope too. Is important to scope all query operations.
  #
  # create(data) - Create a record for the given data and return an entity. Data could be either a hash or an entity.
  # update(id, data) - Update the record corresponding to the id and return the updated entity.
  # delete(id) - Delete the record corresponding to the given entity id.
  # soft_delete(id) - Soft delete the record corresponding to the given entity id.
  # delete_all - Delete all entities from the collection.
  # soft_delete_all - Soft delete all entities from the collection.
  # all - Fetch all the entities from the collection.
  # paginate(page: page, per_page: per_page) - Fetch all the entities from the collection paginated.
  # find(id) - Fetch an entity from the collection by its ID.
  # find_by(attributes) - Fetch an entity from the collection by its attributes.
  # first - Fetch the first entity from the collection.
  # last - Fetch the last entity from the collection.
  # count - Count all entities from the collection.
  #
  # Example
  #
  #   class SubscriptionRepository < Core::Repository
  #
  #     if Rails.env.test?
  #       self.persistence = Core::Persistence::Memory
  #     else
  #       self.persistence = Core::Persistence::ActiveRecord
  #     end
  #     self.persistence_scope = :company_id
  #
  #   end
  #   repo = SubscriptionRepository.new(1)
  #   repo.create({name: "RDStation"})

  class << self

    attr_accessor :persistence, :persistence_scope, :persistence_model, :persistence_identifier_field, :entity_class

  end

  extend Forwardable

  def_delegators :persistence,
                 :create,
                 :update,
                 :delete,
                 :soft_delete,
                 :delete_all,
                 :soft_delete_all,
                 :all,
                 :paginate,
                 :find,
                 :find_by,
                 :first,
                 :last,
                 :count

  attr_reader :persistence_scope_value

  def initialize(persistence_scope_value = nil)
    raise "#{persistence_scope} scope need to be informed" if persistence_scope && persistence_scope_value.nil?
    @persistence_scope_value = persistence_scope_value
  end

  def persistence
    @persistence ||= initialize_persistence
  end

  def persistence_scope
    self.class.persistence_scope
  end

  def persistence_model
    self.class.persistence_model
  end

  def persistence_identifier_field
    self.class.persistence_identifier_field
  end

  def entity_class
    self.class.entity_class
  end

  private

  def convert_persistence_object_to_entity(persistence_object)
    entity_class.new(persistence_object.attributes)
  end

  def convert_entity_attrs_to_persistence_object_attrs(entity)
    entity.attributes
  end

  def initialize_persistence
    self.class.persistence.new(
      scope: persistence_scope,
      scope_value: persistence_scope_value,
      model: persistence_model,
      identifier_field: persistence_identifier_field,
      entity_class: entity_class,
      convert_persistence_object_to_entity: lambda { |persistence_object|
        convert_persistence_object_to_entity(persistence_object)
      },
      convert_entity_attrs_to_persistence_object_attrs: lambda { |entity|
        convert_entity_attrs_to_persistence_object_attrs(entity)
      }
    )
  end

end
