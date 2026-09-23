# An Active Record resource, kept out of the dummy app so the app itself still
# boots without Active Record. Required only by the tests that need a saved record.
require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table(:gadgets) { |t| t.string :type; t.string :name; t.string :category }
  create_table(:gears) { |t| t.references :gadget }
end

class Gadget < ActiveRecord::Base
  has_many :gears
end

class Gizmo < Gadget; end
class Doohickey < Gadget; end

class Gear < ActiveRecord::Base
  belongs_to :gadget, optional: true
end
