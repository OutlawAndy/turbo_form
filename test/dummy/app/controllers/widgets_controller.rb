class WidgetsController < ApplicationController
  def new
    @widget = turbo_form_assign(Widget.new)
  end

  def create
    @widget = Widget.new(params.expect(widget: %i[category flavor notes]))

    if @widget.valid?
      head :created
    else
      render :new, status: :unprocessable_content
    end
  end
end
