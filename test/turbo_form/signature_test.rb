require "test_helper"

class TurboForm::SignatureTest < ActiveSupport::TestCase
  test "round trips the facts the endpoint needs to rebuild a form" do
    signature = verify TurboForm::Signature.new(model_name: "Widget", scope: "gadget", template: "shared/refresh")

    assert_equal "Widget", signature.model_name
    assert_equal "gadget", signature.scope
    assert_equal "shared/refresh", signature.template
  end

  test "resolves the model class it names" do
    assert_equal Widget, TurboForm::Signature.new(model_name: "Widget", scope: "widget").model
  end

  test "is a legal URL path segment" do
    token = TurboForm::Signature.new(model_name: "Widget", scope: "widget").to_s

    assert_match(/\A[\w\-]+--[a-f0-9]+\z/, token)
  end

  test "rejects a tampered token rather than trusting what it names" do
    token = TurboForm::Signature.new(model_name: "Widget", scope: "widget").to_s
    forged = token.sub(/\A[^-]+/) { Base64.urlsafe_encode64(%({"model_name":"Kernel","scope":"widget"}), padding: false) }

    assert_raises(TurboForm::Signature::Invalid) { TurboForm::Signature.verify(forged) }
    assert_raises(TurboForm::Signature::Invalid) { TurboForm::Signature.verify("nonsense") }
  end

  test "names the template that sits alongside the resource's own partial" do
    signature = TurboForm::Signature.new(model_name: "Widget", scope: "widget")

    assert_equal "widgets/dynamic_form", signature.template_for(Widget.new)
  end

  test "prefers an explicitly signed template" do
    signature = TurboForm::Signature.new(model_name: "Widget", scope: "widget", template: "shared/refresh")

    assert_equal "shared/refresh", signature.template_for(Widget.new)
  end

  private
    def verify(signature) = TurboForm::Signature.verify(signature.to_s)
end
