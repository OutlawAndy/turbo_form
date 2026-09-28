module TurboForm::SystemTestHelper
  # Waits for a dynamic form to finish reloading the page. Reads <html> from the
  # document, so it works inside `within` too.
  #
  #   expect_dynamic_form_request { select "Bourbon", from: "Category" }
  #   select "Barrel Aged", from: "Flavor"
  def expect_dynamic_form_request
    completed = page.document.find('html')['data-turbo-form-visits'].to_i + 1

    yield

    page.document.assert_selector "html[data-turbo-form-visits='#{completed}']"
  end
end
