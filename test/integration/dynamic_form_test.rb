require 'test_helper'

class DynamicFormTest < ActionDispatch::IntegrationTest
  test 'a PATCH to the new page renders it from the state the form is in' do
    patch new_widget_url, params: { widget: { category: 'fruit', flavor: 'banana' } }

    assert_response :success
    assert_select 'h1[data-rerender=true]', text: 'New fruit widget'
    assert_equal %w[apple banana cherry], css_select('#flavor-field option').map(&:text)
    assert_equal 'banana', css_select('#flavor-field option[selected]').first.text
  end

  test 'a field the controller does not permit is left out rather than raising' do
    patch new_widget_url, params: { widget: { category: 'fruit', secret: 'x' } }

    assert_response :success
  end

  test 'a controller names the instance variable its form object lives in' do
    patch new_order_url, params: { widget: { category: 'fruit' } }

    assert_response :success
    assert_select 'h1', text: 'New fruit order'
  end

  test 'an ordinary visit with the state in its URL ignores it' do
    get new_widget_url, params: { widget: { category: 'fruit' } }

    assert_select 'h1[data-rerender=false]', text: 'New widget'
    assert_empty css_select('#flavor-field option')
  end
end
