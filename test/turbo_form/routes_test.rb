require 'test_helper'

class TurboForm::RoutesTest < ActiveSupport::TestCase
  test 'draws a PATCH only for the new and edit the resource has' do
    routes = draw { resources :widgets, only: :new, concerns: :turbo_form }

    assert_equal({ controller: 'widgets', action: 'new', dynamic_form: true }, routes.recognize_path('/widgets/new', method: :patch))
    assert_raises(ActionController::RoutingError) { routes.recognize_path('/widgets/1/edit', method: :patch) }
  end

  test 'draws both beside a full resource' do
    routes = draw { resources :widgets, concerns: :turbo_form }

    assert_equal({ controller: 'widgets', action: 'edit', id: '1', dynamic_form: true }, routes.recognize_path('/widgets/1/edit', method: :patch))
  end

  private
  def draw(&block)
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        concern :turbo_form, TurboForm::Routes
        instance_exec(&block)
      end
    end
  end
end
