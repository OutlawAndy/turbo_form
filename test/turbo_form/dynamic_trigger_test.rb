require 'test_helper'

class DynamicTriggerTest < ActionView::TestCase
  setup { @widget = Widget.new(category: 'fruit') }

  # Blank leaves the script to use the element's default -- `input` for a text
  # field, `change` for a select.
  test 'dynamic_trigger: true leaves the event blank' do
    assert_equal '', field(:text_field, :notes, dynamic_trigger: true)['data-turbo-form-trigger']
  end

  test 'a named trigger names that event' do
    assert_equal 'blur', field(:text_field, :notes, dynamic_trigger: :blur)['data-turbo-form-trigger']
  end

  test "keeps the caller's own data attributes" do
    attributes = field(:text_field, :notes, dynamic_trigger: true, data: { action: 'autosave#queue' })

    assert_equal 'autosave#queue', attributes['data-action']
    assert_equal '', attributes['data-turbo-form-trigger']
  end

  test 'leaves untriggered fields alone' do
    assert_nil field(:text_field, :notes)['data-turbo-form-trigger']
  end

  # Ruby folds a trailing `dynamic_trigger:` into `collection_select`'s `options`
  # hash, which is *not* where its HTML attributes live. It has to be moved.
  test 'reaches the select of a collection_select' do
    attributes = field(:collection_select, :category, Widget::FLAVORS.keys, :to_s, :titleize, dynamic_trigger: true)

    assert_equal '', attributes['data-turbo-form-trigger']
    assert_nil attributes['dynamic_trigger']
  end

  test 'reaches the select of a plain select' do
    assert_equal '', field(:select, :category, %w[fruit], dynamic_trigger: true)['data-turbo-form-trigger']
  end

  # The shape SimpleForm produces: it passes `input_html:` through as html_options.
  test 'is honoured from html_options too' do
    attributes = field(:select, :category, %w[fruit], {}, { dynamic_trigger: :change })

    assert_equal 'change', attributes['data-turbo-form-trigger']
  end

  test 'dynamic_action: names the URL and triggers on the default event' do
    attributes = field(:text_field, :notes, dynamic_action: '/widgets/summary')

    assert_equal '/widgets/summary', attributes['data-turbo-form-action']
    assert_equal '', attributes['data-turbo-form-trigger']
  end

  test 'dynamic_action: triggers on the event dynamic_trigger: names' do
    assert_equal 'blur', field(:text_field, :notes, dynamic_action: '/widgets/summary', dynamic_trigger: :blur)['data-turbo-form-trigger']
  end

  test 'dynamic_action: reaches the select of a plain select' do
    attributes = field(:select, :category, %w[fruit], dynamic_action: '/widgets/summary')

    assert_equal '/widgets/summary', attributes['data-turbo-form-action']
    assert_nil attributes['dynamic_action']
  end

  test 'dynamic_action: takes whatever url_for does' do
    assert_equal '/widgets/summary', field(:text_field, :notes, dynamic_action: %i[summary widgets])['data-turbo-form-action']
  end

  test 'reaches a submit' do
    attributes = field(:submit, 'Go', dynamic_trigger: true)

    assert_equal '', attributes['data-turbo-form-trigger']
    assert_nil attributes['dynamic_trigger']
  end

  test 'reaches a button given only options' do
    button = Nokogiri::HTML5.fragment(render_field(:button, type: 'button', dynamic_action: '/widgets/summary')).at('button')

    assert_equal '/widgets/summary', button['data-turbo-form-action']
    assert_nil button['dynamic_action']
  end

  test 'never leaks into the markup' do
    assert_not_includes render_field(:text_field, :notes, dynamic_trigger: true), 'dynamic_trigger'
    assert_not_includes render_field(:text_field, :notes, dynamic_action: '/widgets/summary'), 'dynamic_action'
  end

  # Builder methods other gems add, like country_select's, hand html_options
  # straight to their tag, so the select's renderer picks the trigger up there.
  test 'reaches a select whose builder method passes html_options through untouched' do
    html = fields(model: @widget) { |f| select(f.object_name, :category, %w[fruit], {}, { dynamic_action: '/widgets/summary' }) }
    attributes = Nokogiri::HTML5.fragment(html).at('select').attributes.transform_values(&:value)

    assert_equal '/widgets/summary', attributes['data-turbo-form-action']
    assert_nil attributes['dynamic_action']
  end

  test 'does not mutate the options it was handed' do
    options = { dynamic_trigger: true }
    render_field(:text_field, :notes, **options)

    assert_equal({ dynamic_trigger: true }, options)
  end

  private
  def render_field(helper, ...)
    fields(model: @widget) { |f| f.public_send(helper, ...) }
  end

  def field(helper, ...)
    Nokogiri::HTML5.fragment(render_field(helper, ...)).at('input, select').attributes.transform_values(&:value)
  end
end
