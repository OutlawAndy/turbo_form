# Builds its form object under a name of its own, as a bulk or wizard form
# does when `@order` would mean something else.
class OrdersController < ApplicationController
  def new
    @form = Widget.new
  end

  private
  def turbo_form_resource_name = :form
  def order_params = params.expect(widget: %i[category flavor])
end
