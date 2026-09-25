class WidgetsController < ApplicationController
  def new
    @widget = Widget.new
  end

  def create
    @widget = Widget.new(widget_params)

    if @widget.valid?
      head :created
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def widget_params = params.expect(widget: %i[category flavor notes])
end
