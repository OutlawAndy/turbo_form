# Changelog

## Unreleased

- `dynamic_trigger:` takes a hash: `{ event:, url:, params: }`. A trigger can now
  send the form to an endpoint of its own and add to what it sends, so one form
  can feed several actions.

## 0.2.0

- `expect_dynamic_form_request` now ships with the gem and is available in
  system tests without any setup, under Minitest and RSpec alike.

## 0.1.0

- Initial extraction. `dynamic:` on a form and `dynamic_trigger:` on a field,
  a signed endpoint that re-renders a convention-named turbo_stream template,
  and a self-registering Stimulus controller.
