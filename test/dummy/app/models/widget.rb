# A plain Active Model form object: the flavors on offer depend on the category,
# which is the whole reason the form needs to talk to the server as it is filled in.
class Widget
  include ActiveModel::Model
  include ActiveModel::Attributes

  FLAVORS = {
    "fruit" => %w[apple banana cherry],
    "vegetable" => %w[carrot pea turnip]
  }.freeze

  attribute :category, :string
  attribute :flavor, :string
  attribute :notes, :string

  validates :flavor, presence: true

  def categories = FLAVORS.keys

  def flavors = FLAVORS.fetch(category, [])
end
