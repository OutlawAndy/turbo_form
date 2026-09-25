require "test_helper"

class DynamicFormTest < ActionDispatch::IntegrationTest
  RELOAD = { TurboForm::Reload::HEADER => "reload" }

  test "a reload renders the page from the state the form is currently in" do
    get new_widget_url, params: { widget: { category: "fruit", flavor: "banana" } }, headers: RELOAD

    assert_response :success
    assert_equal %w[apple banana cherry], css_select("#flavor-field option").map(&:text)
    assert_equal "banana", css_select("#flavor-field option[selected]").first.text
  end

  test "an action that asks for the state early can use it above the form" do
    get new_widget_url, params: { widget: { category: "fruit" } }, headers: RELOAD

    assert_select "h1", text: "New fruit widget"
  end

  test "a first visit renders the object as the controller built it" do
    get new_widget_url

    assert_empty css_select("#flavor-field option")
  end

  test "an ordinary visit with the state in its URL ignores it, early or late" do
    get new_widget_url, params: { widget: { category: "fruit" } }

    assert_select "h1", text: "New widget"
    assert_empty css_select("#flavor-field option")
  end
end
