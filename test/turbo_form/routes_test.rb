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

  test "yields to the app's own concern of the same name" do
    routes = draw do
      concern(:turbo_form) { get :preview, on: :collection }
      resources :widgets, only: :new, concerns: :turbo_form
    end

    assert_equal({ controller: 'widgets', action: 'preview' }, routes.recognize_path('/widgets/preview'))
    assert_raises(ActionController::RoutingError) { routes.recognize_path('/widgets/new', method: :patch) }
  end

  private
  def draw(&) = ActionDispatch::Routing::RouteSet.new.tap { it.draw(&) }
end
