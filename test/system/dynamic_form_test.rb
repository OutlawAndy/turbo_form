require 'application_system_test_case'

class DynamicFormSystemTest < ApplicationSystemTestCase
  test 'a trigger reloads the form as the user has it, keeping what else they typed' do
    visit new_widget_path
    fill_in 'Notes', with: 'kept'

    expect_dynamic_form_request { select 'fruit', from: 'Category' }
    select 'banana', from: 'Flavor'

    assert_field 'Notes', with: 'kept'
    assert_current_path new_widget_path, ignore_query: true
  end

  test 'expect_dynamic_form_request waits from inside within' do
    visit new_widget_path

    within('form') { expect_dynamic_form_request { select 'fruit', from: 'Category' } }

    assert_select 'Flavor', with_options: [ 'banana' ]
  end

  test 'Turbo renders the page by morphing it' do
    visit new_widget_path
    execute_script %(addEventListener("turbo:render", ({ detail }) => window.renderMethod = detail.renderMethod))

    expect_dynamic_form_request { select 'fruit', from: 'Category' }

    assert_equal 'morph', evaluate_script('window.renderMethod')
  end

  test "a trigger naming an event that doesn't bubble still fires on it" do
    visit new_widget_path
    execute_script %(document.getElementById("widget_notes").dataset.turboFormTrigger = "blur")

    # Dispatched by hand because Cuprite's own blur bubbles, and a browser's doesn't.
    expect_dynamic_form_request { execute_script %(document.getElementById("widget_notes").dispatchEvent(new FocusEvent("blur"))) }
  end

  test "a trigger added to the page listens for a custom event, like another controller's" do
    visit new_widget_path
    execute_script %(document.getElementById("widget_notes").dataset.turboFormTrigger = "autocomplete:selected")

    expect_dynamic_form_request { execute_script %(document.getElementById("widget_notes").dispatchEvent(new CustomEvent("autocomplete:selected", { bubbles: true }))) }
  end

  test 'a second trigger reloads again' do
    visit new_widget_path

    expect_dynamic_form_request { select 'fruit', from: 'Category' }
    expect_dynamic_form_request { select 'vegetable', from: 'Category' }

    assert_select 'Flavor', options: %w[carrot pea turnip]
  end

  test 'a trigger after a failed save reloads the form it failed on' do
    visit new_widget_path
    click_on 'Save'
    assert_text "Flavor can't be blank"

    expect_dynamic_form_request { select 'fruit', from: 'Category' }

    assert_current_path new_widget_path, ignore_query: true
    assert_select 'Flavor', options: %w[apple banana cherry]
  end

  test 'a trigger inside a frame reloads only the frame' do
    visit new_widget_path
    page.driver.set_cookie('framed', '1')
    visit new_widget_path

    expect_dynamic_form_request { select 'fruit', from: 'Category' }

    assert_select 'Flavor', options: %w[apple banana cherry]
    assert_selector 'h1', text: 'New widget'
  end

  test 'a trigger inside a frame that targets the page reloads the page' do
    visit new_widget_path
    page.driver.set_cookie('framed', '1')
    page.driver.set_cookie('frame_target', '_top')
    visit new_widget_path

    expect_dynamic_form_request { select 'fruit', from: 'Category' }

    assert_selector 'h1', text: 'New fruit widget'
  end

  test "the form and its frame are busy while the trigger's request is out" do
    visit new_widget_path
    page.driver.set_cookie('framed', '1')
    visit new_widget_path
    execute_script <<~JS
      window.busy = []
      new MutationObserver(records => records.forEach(({ target }) => window.busy.push(`${target.localName}:${target.getAttribute("aria-busy")}`)))
        .observe(document.body, { attributeFilter: [ "aria-busy" ], subtree: true })
    JS

    expect_dynamic_form_request { select 'fruit', from: 'Category' }

    assert_equal %w[form:true turbo-frame:true], evaluate_script('window.busy').first(2)
    assert_no_selector '[aria-busy], turbo-frame[busy]'
  end

  test 'a trigger with an action of its own renders the Turbo Stream it answers with' do
    visit new_widget_path
    expect_dynamic_form_request { select 'fruit', from: 'Category' }
    execute_script %(addEventListener("turbo:render", () => window.pageRendered = true))

    expect_dynamic_form_request { select 'banana', from: 'Flavor' }

    assert_selector '#summary', text: 'A banana widget'
    assert_nil evaluate_script('window.pageRendered')
  end

  test 'a button with an action of its own renders the stream a failed validation answers with' do
    visit new_widget_path

    expect_dynamic_form_request { click_on 'Summarize' }

    assert_selector '#summary', text: "Flavor can't be blank"
  end

  test 'a trigger on the input event sends the form once typing pauses' do
    visit new_widget_path
    execute_script %(document.getElementById("widget_notes").dataset.turboFormTrigger = "")
    execute_script %(window.visits = 0; addEventListener("turbo:visit", () => window.visits++))

    expect_dynamic_form_request { fill_in 'Notes', with: 'abc' }

    assert_equal 1, evaluate_script('window.visits')
    assert_field 'Notes', with: 'abc'
  end

  test 'a trigger with its debounce turned off sends the form on every input' do
    visit new_widget_path
    execute_script %(Object.assign(document.getElementById("widget_notes").dataset, { turboFormTrigger: "", turboFormDebounce: "0" }))

    execute_script %(window.fetches = 0; const { fetch } = window; window.fetch = (...args) => (window.fetches++, fetch(...args)))

    expect_dynamic_form_request { fill_in 'Notes', with: 'abc' }

    assert_equal 3, evaluate_script('window.fetches')
  end

  test 'a debounced trigger gone from the page by the time it would fire sends nothing' do
    visit new_widget_path
    execute_script %(document.getElementById("widget_notes").dataset.turboFormTrigger = "")
    execute_script %(window.fetches = 0; const { fetch } = window; window.fetch = (...args) => (window.fetches++, fetch(...args)))

    fill_in 'Notes', with: 'abc'
    execute_script %(document.getElementById("widget_notes").remove())
    sleep 0.4 # past the debounce

    assert_equal 0, evaluate_script('window.fetches')
  end

  test 'what is typed while a debounced request is out survives its response' do
    visit new_widget_path
    page.driver.set_cookie('delay_', '0.5')
    execute_script %(Object.assign(document.getElementById("widget_notes").dataset, { turboFormTrigger: "", turboFormDebounce: "100" }))
    notes = find_field('Notes')

    expect_dynamic_form_request do
      notes.send_keys('ab')
      sleep 0.2 # the debounce has fired and its request is out
      notes.send_keys('c')
    end

    assert_equal 'abc', evaluate_script(%(document.getElementById("widget_notes").value))
  end

  test 'a response overtaken by a later one is not rendered over it' do
    visit new_widget_path
    execute_script <<~JS
      const { fetch } = window
      window.fetch = async (url, options) => {
        const response = await fetch(url, options)
        if (options.body.get("widget[category]") == "fruit") await new Promise(resolve => setTimeout(resolve, 500))
        return response
      }
    JS

    # In one script, since Cuprite waits out the network after each select
    execute_script <<~JS
      const category = document.getElementById("widget_category")
      for (const value of [ "fruit", "vegetable" ]) {
        category.value = value
        category.dispatchEvent(new Event("change", { bubbles: true }))
      }
    JS
    sleep 1 # both responses are in

    assert_select 'Flavor', options: %w[carrot pea turnip]
  end
end
