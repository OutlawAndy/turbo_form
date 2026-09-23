require "test_helper"

class DynamicFormTest < ActionDispatch::IntegrationTest
  test "re-renders a dependent field from the state the form is currently in" do
    patch dynamic_form_url, params: { widget: { category: "fruit", flavor: "" } }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    flavors = css_select("turbo-stream[action=update][target=flavor-field] option").map(&:text)
    assert_equal %w[apple banana cherry], flavors
  end

  test "hands the whole submitted form to the resource" do
    patch dynamic_form_url, params: { widget: { category: "vegetable", flavor: "pea", notes: "kept" } }, as: :turbo_stream

    assert_equal "pea", css_select("turbo-stream option[selected=selected]").first.text
  end

  # The template belongs to the host app, so its own route helpers have to work
  # inside it exactly as they would anywhere else.
  test "renders the host's route helpers" do
    patch dynamic_form_url, params: { widget: { category: "fruit" } }, as: :turbo_stream

    assert_select "turbo-stream a[href=?]", "/widgets", text: "back"
  end

  test "finds the template through the prefixes the form was rendered under" do
    signature = TurboForm::Signature.new(model_name: "Widget", scope: "widget", prefixes: %w[missing widgets])
    patch turbo_form_path(signature), params: { widget: { category: "fruit" } }, as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[target=flavor-field]"
  end

  test "refuses a signature it did not sign" do
    patch "/turbo_form/forged--0000", params: { widget: { category: "fruit" } }, as: :turbo_stream

    assert_response :bad_request
  end

  test "runs the before_render hook inside the controller, with the rebuilt resource" do
    with_before_render ->(resource) { gatekeep(resource) } do
      patch dynamic_form_url, params: { widget: { category: "vegetable" } }, as: :turbo_stream
      assert_response :forbidden

      patch dynamic_form_url, params: { widget: { category: "fruit" } }, as: :turbo_stream
      assert_response :success
    end
  end

  private
    def with_before_render(hook)
      TurboForm.before_render = hook
      yield
    ensure
      TurboForm.before_render = nil
    end

    # The browser only ever learns this URL by reading it off the rendered form,
    # so the test does the same.
    def dynamic_form_url
      get new_widget_url
      css_select("form").first["data-turbo-form-url-value"]
    end
end
