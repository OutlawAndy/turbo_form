require "application_system_test_case"

class DynamicFormSystemTest < ApplicationSystemTestCase
  test "a trigger reloads the form as the user has it, keeping what else they typed" do
    visit new_widget_path
    fill_in "Notes", with: "kept"

    expect_dynamic_form_request { select "fruit", from: "Category" }
    select "banana", from: "Flavor"

    assert_field "Notes", with: "kept"
    assert_current_path new_widget_path, ignore_query: true
  end

  test "a second trigger reloads again" do
    visit new_widget_path

    expect_dynamic_form_request { select "fruit", from: "Category" }
    expect_dynamic_form_request { select "vegetable", from: "Category" }

    assert_select "Flavor", options: %w[carrot pea turnip]
  end

  test "a trigger after a failed save reloads the form it failed on" do
    visit new_widget_path
    click_on "Save"
    assert_text "Flavor can't be blank"

    expect_dynamic_form_request { select "fruit", from: "Category" }

    assert_current_path new_widget_path, ignore_query: true
    assert_select "Flavor", options: %w[apple banana cherry]
  end
end
