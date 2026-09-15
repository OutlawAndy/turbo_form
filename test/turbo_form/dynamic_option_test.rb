require "test_helper"

class DynamicOptionTest < ActionView::TestCase
  setup { @widget = Widget.new }

  test "dynamic: true hands the form to the Stimulus controller" do
    attributes = form_attributes(form_for(@widget, dynamic: true) { "" })

    assert_equal "turbo-form", attributes["data-controller"]
    assert_match %r{\A/turbo_form/}, attributes["data-turbo-form-url-value"]
  end

  test "signs the class and scope the endpoint will need" do
    signature = signature_in(form_for(@widget, dynamic: true) { "" })

    assert_equal "Widget", signature.model_name
    assert_equal "widget", signature.scope
    assert_nil signature.template
  end

  test "form_with is wired the same way, since form_for funnels through it" do
    attributes = form_attributes(form_with(model: @widget, dynamic: true) { "" })

    assert_equal "turbo-form", attributes["data-controller"]
    assert_equal "widget", signature_in(form_with(model: @widget, dynamic: true) { "" }).scope
  end

  test "honours an explicit scope" do
    form = form_with(model: @widget, scope: :gadget, dynamic: true) { "" }

    assert_equal "gadget", signature_in(form).scope
  end

  test "a string names the template to render instead of the conventional one" do
    assert_equal "shared/refresh", signature_in(form_for(@widget, dynamic: "shared/refresh") { "" }).template
  end

  test "keeps company with the caller's own Stimulus controllers" do
    form = form_for(@widget, dynamic: true, html: { data: { controller: "autosave", turbo: false } }) { "" }
    attributes = form_attributes(form)

    assert_equal "autosave turbo-form", attributes["data-controller"]
    assert_equal "false", attributes["data-turbo"]
  end

  test "leaves ordinary forms exactly as Rails renders them" do
    assert_equal form_for(@widget) { "" }, form_for(@widget, dynamic: false) { "" }
  end

  test "explains itself when there is no object to rebuild" do
    error = assert_raises(ArgumentError) { form_with(scope: :search, url: "/search", dynamic: true) { "" } }

    assert_match(/model/, error.message)
  end

  private
    def form_attributes(html)
      Nokogiri::HTML5.fragment(html).at("form").attributes.transform_values(&:value)
    end

    def signature_in(html)
      TurboForm::Signature.verify(form_attributes(html)["data-turbo-form-url-value"].split("/").last)
    end
end
