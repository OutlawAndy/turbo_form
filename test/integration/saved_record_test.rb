require "test_helper"
require "support/gadget"

class SavedRecordTest < ActionDispatch::IntegrationTest
  teardown { [ Gear, Gadget ].each(&:delete_all) }

  test "an edit form re-renders from the saved record, with what was typed on top" do
    gadget = Gadget.create!(name: "kept", category: "fruit")

    patch dynamic_form_url(id: gadget.id), params: { gadget: { category: "vegetable" } }, as: :turbo_stream

    assert_select "turbo-stream[target=gadget] template", text: "kept vegetable 0"
  end

  test "a new form keeps what it was built with, though the form never sends it" do
    patch dynamic_form_url(seed: { "name" => "seeded" }), params: { gadget: { category: "fruit" } }, as: :turbo_stream

    assert_select "turbo-stream[target=gadget] template", text: "seeded fruit 0"
  end

  test "writes that assignment makes on its own are rolled back" do
    gadget = Gadget.create!(name: "kept", gears: [ Gear.new ])

    patch dynamic_form_url(id: gadget.id), params: { gadget: { gear_ids: [ "" ] } }, as: :turbo_stream

    assert_select "turbo-stream[target=gadget] template", text: /kept\s+0/
    assert_equal 1, gadget.gears.reload.size
  end

  private
    def dynamic_form_url(**origin)
      turbo_form_path(TurboForm::Signature.new(model_name: "Gadget", scope: "gadget", prefixes: [ "gadgets" ], **origin))
    end
end

class SavedRecordFormTest < ActionView::TestCase
  teardown { Gadget.delete_all }

  test "a saved record is signed by id" do
    signature = signature_in(form_with(model: Gadget.create!(name: "kept"), url: "/", dynamic: true) { "" })

    assert_kind_of Integer, signature.id
    assert_empty signature.seed
  end

  test "an unsaved record is signed with what it was built with" do
    signature = signature_in(form_with(model: Gadget.new(name: "seeded"), url: "/", dynamic: true) { "" })

    assert_nil signature.id
    assert_equal({ "name" => "seeded" }, signature.seed)
  end

  private
    def signature_in(form)
      url = Nokogiri::HTML5.fragment(form).at("form")["data-turbo-form-url-value"]
      TurboForm::Signature.verify(url.delete_prefix("/turbo_form/"))
    end
end
