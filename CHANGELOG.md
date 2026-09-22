# Changelog

## Unreleased

- The npm package is now `@rolemodel/turbo-form`, matching `@rolemodel/turbo-confirm`.
  Bundled apps installing it by the old `@rolemodel/turbo_form` name need to
  update the dependency and the import. The gem name is unchanged.

## 0.2.0

- `expect_dynamic_form_request` now ships with the gem and is available in
  system tests without any setup, under Minitest and RSpec alike.

## 0.1.0

- Initial extraction. `dynamic:` on a form and `dynamic_trigger:` on a field,
  a signed endpoint that re-renders a convention-named turbo_stream template,
  and a self-registering Stimulus controller.
