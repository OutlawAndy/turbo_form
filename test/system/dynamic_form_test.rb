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

  test "a trigger inside a frame reloads only the frame" do
    visit new_widget_path
    page.driver.set_cookie("framed", "1")
    visit new_widget_path

    expect_dynamic_form_request { select "fruit", from: "Category" }

    assert_select "Flavor", options: %w[apple banana cherry]
    assert_selector "h1", text: "New widget"
  end

  test "a trigger inside a frame that targets the page reloads the page" do
    visit new_widget_path
    page.driver.set_cookie("framed", "1")
    page.driver.set_cookie("frame_target", "_top")
    visit new_widget_path

    expect_dynamic_form_request { select "fruit", from: "Category" }

    assert_selector "h1", text: "New fruit widget"
  end

  test "the form and its frame are busy while the trigger's request is out" do
    visit new_widget_path
    page.driver.set_cookie("framed", "1")
    visit new_widget_path
    execute_script <<~JS
      window.busy = []
      new MutationObserver(records => records.forEach(({ target }) => window.busy.push(`${target.localName}:${target.getAttribute("aria-busy")}`)))
        .observe(document.body, { attributeFilter: [ "aria-busy" ], subtree: true })
    JS

    expect_dynamic_form_request { select "fruit", from: "Category" }

    assert_equal %w[form:true turbo-frame:true], evaluate_script("window.busy").first(2)
    assert_no_selector "[aria-busy], turbo-frame[busy]"
  end
end
