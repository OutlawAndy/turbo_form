require "test_helper"

class DynamicOptionTest < ActionView::TestCase
  setup { @widget = Widget.new }

  test "dynamic: true hands the form to the Stimulus controller" do
    assert_equal "turbo-form", form_attributes(form_for(@widget, dynamic: true) { "" })["data-controller"]
  end

  test "form_with is wired the same way, since form_for funnels through it" do
    assert_equal "turbo-form", form_attributes(form_with(model: @widget, dynamic: true) { "" })["data-controller"]
  end

  test "keeps dynamic: out of the form's HTML" do
    assert_nil form_attributes(form_with(model: @widget, dynamic: true) { "" })["dynamic"]
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

  test "assigns the submitted state to its object before the fields render" do
    reload!
    params[:widget] = { category: "fruit", flavor: "banana" }

    form = form_for(@widget, dynamic: true) { |f| f.select :flavor, @widget.flavors }

    assert_equal %w[apple banana cherry], Nokogiri::HTML5.fragment(form).css("option").map(&:text)
    assert_equal "banana", @widget.flavor
  end

  test "honours an explicit scope" do
    reload!
    params[:gadget] = { category: "fruit" }

    form_with(model: @widget, scope: :gadget, dynamic: true) { "" }

    assert_equal "fruit", @widget.category
  end

  test "an ordinary form leaves its object alone" do
    reload!
    params[:widget] = { category: "fruit" }

    form_for(@widget) { "" }

    assert_nil @widget.category
  end

  test "an ordinary visit to the same URL leaves its object alone" do
    params[:widget] = { category: "fruit" }

    form_for(@widget, dynamic: true) { "" }

    assert_nil @widget.category
  end

  test "ignores a scope that isn't a hash" do
    reload!
    params[:widget] = "fruit"

    form_for(@widget, dynamic: true) { "" }

    assert_nil @widget.category
  end

  private
    def reload! = request.headers[TurboForm::Reload::HEADER] = "reload"

    def form_attributes(html)
      Nokogiri::HTML5.fragment(html).at("form").attributes.transform_values(&:value)
    end
end
