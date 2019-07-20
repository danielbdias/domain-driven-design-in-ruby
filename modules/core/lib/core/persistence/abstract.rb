class Core::Persistence::Abstract

  def initialize(scope: nil, scope_value: nil, **)
    @scope = scope
    @scope_value = scope_value
  end

  attr_reader :scope
  attr_accessor :scope_value

  def self.transaction
    raise NotImplementedError, "#{name} -> " \
      "No Implemented self.transaction"
  end

  def self.transaction_rollback
    raise NotImplementedError, "#{name} -> " \
      "No Implemented self.transaction_rollback"
  end

  def create(data)
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented create(data), data: #{data}"
  end

  def update(id, data)
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented update(id, data), id: #{id}, data: #{data}"
  end

  def delete(id)
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented delete(id), id: #{id}"
  end

  def soft_delete(id)
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented soft_delete(id), id: #{id}"
  end

  def delete_all
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented delete_all"
  end

  def soft_delete_all
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented soft_delete_all"
  end

  def all
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented all"
  end

  def paginate(page:, page_size:)
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented paginate(page:, page_size:), page: #{page}, page_size: #{page_size}"
  end

  def find(id)
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented find(id), id: #{id}"
  end

  def find_by(attributes)
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented find_by(attributes), attributes: #{attributes}"
  end

  def first
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented first"
  end

  def last
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented last"
  end

  def count
    raise NotImplementedError, "#{self.class.name} -> " \
      "No Implemented count"
  end

end
