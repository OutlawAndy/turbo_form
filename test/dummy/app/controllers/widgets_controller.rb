class WidgetsController < ApplicationController
  # Cookies rather than params, since the form reloads a URL of its own:
  # delay_fruit slows a trigger sent with the fruit category, delay_ one sent without.
  before_action { sleep cookies["delay_#{params.dig(:widget, :category)}"].to_f if request.patch? }

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

  def summary
    @widget = Widget.new(widget_params)

    render status: @widget.valid? ? :ok : :unprocessable_content
  end

  private
  def widget_params = params.expect(widget: %i[category flavor notes])
end
