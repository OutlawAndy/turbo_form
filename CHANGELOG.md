# Changelog

## Unreleased

- The endpoint rebuilds the form's own object instead of a blank one. An edit
  form's record is found again by id, so nested records posted with ids no
  longer raise `RecordNotFound`; a new form keeps the attributes it was built
  with, such as a parent's foreign key. Active Record resources are rebuilt in a
  transaction that is always rolled back, since some assignments save on the spot.

- **Breaking:** `dynamic: true` finds its template next to the view that
  rendered the form rather than next to the model's partial, so a form on
  `decks/new` gets `decks/dynamic_form` even when `Deck#to_partial_path` points
  elsewhere. Partials rendered from the template now resolve relative to that
  view too, instead of needing full paths. Forms rendered before upgrading carry
  no view paths and need a reload.

## 0.3.0

- `dynamic_trigger:` takes a hash: `{ event:, url:, params: }`. A trigger can now
  send the form to an endpoint of its own and add to what it sends, so one form
  can feed several actions.
- `rails generate turbo_form:install` sets up bundled apps: adds the npm package
  with the manager the app's lockfile names, and registers the Stimulus
  controller by filename so `rails generate stimulus` can't erase it. Importmap
  apps still need nothing, and the generator tells them so.
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
