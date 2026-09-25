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

  private
    def with_gadget_routes(&)
      with_routing do |routes|
        routes.draw { get "/gadgets/:id/edit" => "gadgets#edit" }
        yield
      end
    end
end
