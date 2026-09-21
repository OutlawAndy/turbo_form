module TurboForm::SystemTestHelper
  # Waits for a dynamic form to finish re-rendering itself.
  #
  # A trigger sends the form to the server and swaps part of it out when the
  # response lands, so anything a test does on the next line is racing that
  # response -- and loses often enough to be flaky rather than broken. The
  # Stimulus controller counts completed round trips; waiting on that count is
  # both cheaper and steadier than waiting on whichever field came back.
  #
  #   expect_dynamic_form_request { select "Bourbon", from: "Category" }
  #   select "Barrel Aged", from: "Flavor"
  #
  # Scope it with Capybara's own `within` when a page carries more than one
  # dynamic form.
  def expect_dynamic_form_request
    form = page.find("[data-controller~='turbo-form']")
    completed = form["data-turbo-form-requests-value"].to_i + 1

    yield

    page.assert_selector "[data-turbo-form-requests-value='#{completed}']"
  end
end
