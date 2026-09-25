require "test_helper"

class DynamicOptionTest < ActionView::TestCase
  setup { @widget = Widget.new }

  test "dynamic: true points the form at the page it is on" do
    assert_equal "/widgets/new", form_attributes(form_for(@widget, dynamic: true) { "" })["data-turbo-form-url"]
  end

  test "form_with is wired the same way, since form_for funnels through it" do
    assert_equal "/widgets/new", form_attributes(form_with(model: @widget, dynamic: true) { "" })["data-turbo-form-url"]
  end

  test "keeps dynamic: out of the form's HTML" do
    assert_nil form_attributes(form_with(model: @widget, dynamic: true) { "" })["dynamic"]
  end

  test "keeps the caller's own data attributes" do
    form = form_for(@widget, dynamic: true, html: { data: { controller: "autosave", turbo: false } }) { "" }
    attributes = form_attributes(form)

    assert_equal "autosave", attributes["data-controller"]
    assert_equal "false", attributes["data-turbo"]
  end

  test "leaves ordinary forms exactly as Rails renders them" do
    assert_equal form_for(@widget) { "" }, form_for(@widget, dynamic: false) { "" }
  end

  private
    def form_attributes(html)
      Nokogiri::HTML5.fragment(html).at("form").attributes.transform_values(&:value)
    end
end
