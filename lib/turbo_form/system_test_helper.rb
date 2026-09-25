module TurboForm::SystemTestHelper
  # Waits for a dynamic form to finish reloading the page.
  #
  #   expect_dynamic_form_request { select "Bourbon", from: "Category" }
  #   select "Barrel Aged", from: "Flavor"
  def expect_dynamic_form_request
    completed = page.find("html")["data-turbo-form-visits"].to_i + 1

    yield

    page.assert_selector "html[data-turbo-form-visits='#{completed}']"
  end
end
