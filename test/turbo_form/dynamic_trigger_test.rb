require "test_helper"

class DynamicTriggerTest < ActionView::TestCase
  setup { @widget = Widget.new(category: "fruit") }

  # `true` leaves the event off the descriptor so Stimulus uses the element's
  # default -- `input` for a text field, `change` for a select.
  test "dynamic_trigger: true binds the element's default event" do
    assert_equal "turbo-form#perform", field(:text_field, :notes, dynamic_trigger: true)["data-action"]
  end

  test "a named trigger binds that event" do
    assert_equal "blur->turbo-form#perform", field(:text_field, :notes, dynamic_trigger: :blur)["data-action"]
  end

  test "joins an action the caller already asked for" do
    attributes = field(:text_field, :notes, dynamic_trigger: true, data: { action: "autosave#queue" })

    assert_equal "autosave#queue turbo-form#perform", attributes["data-action"]
  end

  # The field that answers to a different endpoint than its own form: the URL
  # rides on the trigger, so one form can feed several actions.
  test "a trigger can name its own url" do
    attributes = field(:text_field, :notes, dynamic_trigger: { url: "/preview" })

    assert_equal "turbo-form#perform", attributes["data-action"]
    assert_equal "/preview", attributes["data-turbo-form-url-param"]
  end

  test "a trigger can name an event alongside its url" do
    attributes = field(:text_field, :notes, dynamic_trigger: { event: :blur, url: "/preview" })

    assert_equal "blur->turbo-form#perform", attributes["data-action"]
    assert_equal "/preview", attributes["data-turbo-form-url-param"]
  end

  # Stimulus JSON-parses a param, so the server can be told which of several
  # things on the page asked -- without the form carrying it as a field.
  test "a trigger can send extra params with the form" do
    attributes = field(:text_field, :notes, dynamic_trigger: { params: { attribute: "rafter_count" } })

    assert_equal %({"attribute":"rafter_count"}), attributes["data-turbo-form-query-param"]
  end

  test "leaves untriggered fields alone" do
    assert_nil field(:text_field, :notes)["data-action"]
  end

  test "leaves the params off a trigger that names none" do
    attributes = field(:text_field, :notes, dynamic_trigger: :blur)

    assert_nil attributes["data-turbo-form-url-param"]
    assert_nil attributes["data-turbo-form-query-param"]
  end

  # Ruby folds a trailing `dynamic_trigger:` into `collection_select`'s `options`
  # hash, which is *not* where its HTML attributes live. It has to be moved.
  test "reaches the select of a collection_select" do
    attributes = field(:collection_select, :category, Widget::FLAVORS.keys, :to_s, :titleize, dynamic_trigger: true)

    assert_equal "turbo-form#perform", attributes["data-action"]
    assert_nil attributes["dynamic_trigger"]
  end

  test "carries a trigger's url across to a select" do
    attributes = field(:select, :category, %w[fruit], dynamic_trigger: { url: "/preview" })

    assert_equal "/preview", attributes["data-turbo-form-url-param"]
  end

  test "reaches the select of a plain select" do
    assert_equal "turbo-form#perform", field(:select, :category, %w[fruit], dynamic_trigger: true)["data-action"]
  end

  # The shape SimpleForm produces: it passes `input_html:` through as html_options.
  test "is honoured from html_options too" do
    attributes = field(:select, :category, %w[fruit], {}, { dynamic_trigger: :change })

    assert_equal "change->turbo-form#perform", attributes["data-action"]
  end

  test "never leaks into the markup" do
    assert_not_includes render_field(:text_field, :notes, dynamic_trigger: true), "dynamic_trigger"
  end

  test "does not mutate the options it was handed" do
    options = { dynamic_trigger: true }
    render_field(:text_field, :notes, **options)

    assert_equal({ dynamic_trigger: true }, options)
  end

  private
    def render_field(helper, ...)
      fields(model: @widget) { |f| f.public_send(helper, ...) }
    end

    def field(helper, ...)
      Nokogiri::HTML5.fragment(render_field(helper, ...)).at("input, select").attributes.transform_values(&:value)
    end
end
