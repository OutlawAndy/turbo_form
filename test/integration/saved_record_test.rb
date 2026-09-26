require 'test_helper'
require 'support/gadget'

class GadgetsController < ApplicationController
  before_action :set_gadget, only: :edit

  def new
    @gadget = Gadget.new
  end

  def edit
  end

  private
  def set_gadget = @gadget = Gadget.find(params[:id])

  def gadget_params = params.expect(gadget: [ :type, :name, gear_ids: [] ])
end

class SavedRecordTest < ActionDispatch::IntegrationTest
  setup { @gadget = Gadget.create!(name: 'kept', gears: [ Gear.new ]) }
  teardown { [ Gear, Gadget ].each(&:delete_all) }

  test 'the edit page renders what assignment did, and keeps none of it' do
    with_gadget_routes { patch "/gadgets/#{@gadget.id}/edit", params: { gadget: { gear_ids: [ '' ] } } }

    assert_select '#gears', text: '0'
    assert_equal 1, @gadget.gears.reload.size
  end

  test 'the object is switched to the subclass the form names' do
    gizmo = Gizmo.create!(name: 'kept')

    with_gadget_routes { patch "/gadgets/#{gizmo.id}/edit", params: { gadget: { type: 'Doohickey' } } }

    assert_select '#class', text: 'Doohickey kept'
    assert_equal 'Gizmo', Gadget.find(gizmo.id).type
  end

  test 'a new record switched to a subclass keeps the records assigned to it' do
    gear = Gear.create!

    with_gadget_routes { patch '/gadgets/new', params: { gadget: { type: 'Doohickey', name: 'fresh', gear_ids: [ gear.id ] } } }

    assert_select '#class', text: 'Doohickey fresh'
    assert_select '#gears', text: '1'
  end

  private
  def with_gadget_routes(&)
    with_routing do |routes|
      routes.draw do
        concern :turbo_form, TurboForm::Routes
        resources :gadgets, only: %i[new edit], concerns: :turbo_form
      end
      yield
    end
  end
end
