class WidgetsController < ApplicationController
  def new
    @widget = Widget.new
  end

  def create
    head :created
  end
end
