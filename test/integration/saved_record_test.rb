require "test_helper"
require "support/gadget"

class GadgetsController < ApplicationController
  def edit
    @gadget = Gadget.find(params[:id])

    render inline: <<~ERB
      <%= form_with model: @gadget, url: "/", dynamic: true do |f| %>
        <%= f.collection_select :gear_ids, Gear.all, :id, :id, {}, multiple: true %>
      <% end %>
      <p id="gears"><%= @gadget.gears.size %></p>
    ERB
  end
end

class GizmosController < ApplicationController
  def edit
    @gadget = turbo_form_assign(Gadget.find(params[:id]), scope: :gadget)

    render inline: %(<p id="class"><%= @gadget.class %> <%= @gadget.name %></p>)
  end
end

class SavedRecordTest < ActionDispatch::IntegrationTest
  RELOAD = { TurboForm::Reload::HEADER => "reload" }

  setup { @gadget = Gadget.create!(name: "kept", gears: [ Gear.new ]) }
  teardown { [ Gear, Gadget ].each(&:delete_all) }

  test "a reload renders what assignment did, and keeps none of it" do
    with_gadget_routes do
      get "/gadgets/#{@gadget.id}/edit", params: { gadget: { gear_ids: [ "" ] } }, headers: RELOAD
    end

    assert_select "#gears", text: "0"
    assert_equal 1, @gadget.gears.reload.size
  end

  test "a crafted link without the header assigns nothing" do
    with_gadget_routes do
      get "/gadgets/#{@gadget.id}/edit", params: { gadget: { gear_ids: [ "" ] } }
    end

    assert_select "#gears", text: "1"
    assert_equal 1, @gadget.gears.reload.size
  end

  test "an action can keep the subclass the form switched to" do
    gizmo = Gizmo.create!(name: "kept")

    with_gadget_routes do
      get "/gizmos/#{gizmo.id}/edit", params: { gadget: { type: "Doohickey" } }, headers: RELOAD
    end

    assert_select "#class", text: "Doohickey kept"
    assert_equal "Gizmo", Gadget.find(gizmo.id).type
  end

  private
    def with_gadget_routes(&)
      with_routing do |routes|
        routes.draw do
          get "/gadgets/:id/edit" => "gadgets#edit"
          get "/gizmos/:id/edit" => "gizmos#edit"
        end
        yield
      end
    end
end

class SubclassFormTest < ActionView::TestCase
  setup { request.headers[TurboForm::Reload::HEADER] = "reload" }
  teardown { Gadget.delete_all }

  test "the form renders as the subclass it was switched to, keeping what was saved" do
    params[:gadget] = { type: "Doohickey", category: "fruit" }

    form_with(model: Gizmo.create!(name: "kept"), scope: :gadget, url: "/", dynamic: true) { |f| @rendered_as = f.object }

    assert_instance_of Doohickey, @rendered_as
    assert_equal %w[kept fruit], [ @rendered_as.name, @rendered_as.category ]
  end

  test "a form that doesn't mention the type keeps the saved subclass" do
    params[:gadget] = { category: "fruit" }

    form_with(model: Gizmo.create!(name: "kept"), scope: :gadget, url: "/", dynamic: true) { |f| @rendered_as = f.object }

    assert_instance_of Gizmo, @rendered_as
  end

  test "a new record switches too" do
    params[:gadget] = { type: "Doohickey" }

    form_with(model: Gadget.new, scope: :gadget, url: "/", dynamic: true) { |f| @rendered_as = f.object }

    assert_instance_of Doohickey, @rendered_as
  end
end
