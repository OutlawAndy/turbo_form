# Changelog

## [v0.10.0] Oct 18, 2026

- Triggers on the `input` event wait for a 300ms pause before sending the form;
  `dynamic_debounce:` names a wait of its own for any trigger, or `false` for none
- The field being typed in keeps its value when a trigger's response is morphed in
- A response overtaken by a later one to the same URL is no longer rendered

## [v0.9.1] Oct 12, 2026

- Date and link each CHANGELOG release (#36)
- Use the shared release workflow from RoleModel/actions (#35)

## [v0.9.0] Sep 29, 2026

- The engine includes `TurboForm::Controller` in `ActionController::Base` and
  declares the `:turbo_form` route concern itself, so drawing
  `concerns: :turbo_form` on a resource is the only setup a dynamic form needs.
  The installer now only imports the script. Apps that include the module and
  declare the concern themselves keep working; both lines can go.

## [v0.8.1] Sep 28, 2026

- `dynamic_trigger:` and `dynamic_action:` work on selects from other gems'
  builder methods, like country_select's, which skip TurboForm's builder.
- `expect_dynamic_form_request` works inside `within`.

## [v0.8.0] Sep 28, 2026

- `dynamic_action:` on a field sends the form to a URL of its own instead of
  its page, and renders the Turbo Stream the app answers with, whatever its
  status. It takes anything `url_for` does, triggers on the field's default
  event unless `dynamic_trigger:` names one, and doesn't need `dynamic: true`.
- `f.submit` and `f.button` take `dynamic_trigger:` and `dynamic_action:`. They
  used to write them into the markup as raw attributes. A `type="button"`
  triggers on `click`.
- `turbo_form_render?`, a controller and view helper, tells a trigger's
  re-render from an ordinary visit, for a layout or template that should answer
  differently to one.

## [v0.7.1] Sep 28, 2026

- A trigger sends the page's CSRF token, which vouches for any request, instead
  of the form's own, which per-form tokens scope to its action and method.

## [v0.7.0] Sep 26, 2026

- A dynamic `new` or `edit` that calls `render` itself, such as
  `render layout: 'panel'`, now renders what was typed. Only Rails' implicit
  render used to be assigned to.

## [v0.6.0] Sep 26, 2026

- **Breaking:** the Stimulus controller is gone, along with the
  `@hotwired/stimulus` peer dependency. The script listens on the document
  instead: `import "turbo_form"` (importmap) or `import "@rolemodel/turbo-form"`
  (bundled) once in `application.js`, which `rails generate turbo_form:install`
  now adds. Delete the generated `app/javascript/controllers/turbo_form_controller.js`.
  Hand-written `data-controller="turbo-form"` and `turbo-form#perform` become
  `data-turbo-form-url` on the form and `data-turbo-form-trigger` on the field;
  call `refresh(form)` from your own code in place of the action.
- **Breaking:** a trigger PATCHes its form to the page it is on, which runs that
  page's own `new` or `edit`, callbacks and all, assigns `<resource>_params` to
  `@<resource>` and renders the page's own template, inside a transaction that
  is always rolled back. Include `TurboForm::Controller` in ApplicationController,
  declare `concern :turbo_form, TurboForm::Routes` and draw it on each resource
  with a dynamic form, where it routes whichever of `new` and `edit` the resource
  has; `rails generate turbo_form:install` does the first two.
  Because the controller assigns before anything renders, the whole page sees
  what was typed, and only what the params method permits is assigned.
- **Breaking:** `turbo_form_assign`, the `X-Turbo-Form` header and its rollback
  middleware are gone, and the form builder no longer assigns. Drop
  `turbo_form_assign(...)` calls and keep the object they wrapped.
- The form travels in the request body rather than the URL, so large forms, file
  inputs and browser history are no longer a concern.
- A form inside a Turbo Frame asks for, and morphs, only that frame, and marks
  the form and frame busy while its request is out.

## [v0.5.0] Sep 25, 2026

- **Breaking:** a trigger reloads its own page with the form's state in the
  query string, and the form assigns that state to its object before its fields
  render. The endpoint, its route, the signature, `dynamic_form` templates,
  `TurboForm.before_render` and the trigger's `url:`/`params:` are gone.
- `turbo_form_assign(object)` assigns in the controller, for state needed above
  the form.
- A reload carries an `X-Turbo-Form` header and runs in a transaction that is
  always rolled back; a request without the header assigns nothing.

## [v0.4.0] Sep 23, 2026

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

- **Breaking:** `TurboForm.before_render` runs inside the endpoint and takes only
  the resource: `->(resource) { authorize resource, :new? }`. Protected helpers
  such as Pundit's `authorize` and `skip_authorization` were out of reach of the
  old `->(controller, resource)` form. Drop the `controller` argument and its
  receiver.

- A form for an STI subclass signs its base class, and a rebuilt record takes
  the subclass its submitted `type` names — so switching type on a new or edit
  form re-renders as the new subclass instead of raising `SubclassNotFound` or
  keeping the saved one.

## [v0.3.0] Sep 22, 2026

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

## v0.2.0 Sep 21, 2026

- `expect_dynamic_form_request` now ships with the gem and is available in
  system tests without any setup, under Minitest and RSpec alike.

## v0.1.0 Sep 18, 2026

- Initial extraction. `dynamic:` on a form and `dynamic_trigger:` on a field,
  a signed endpoint that re-renders a convention-named turbo_stream template,
  and a self-registering Stimulus controller.

[v0.10.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.10.0
[v0.9.1]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.9.1
[v0.9.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.9.0
[v0.8.1]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.8.1
[v0.8.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.8.0
[v0.7.1]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.7.1
[v0.7.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.7.0
[v0.6.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.6.0
[v0.5.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.5.0
[v0.4.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.4.0
[v0.3.0]: https://github.com/OutlawAndy/turbo_form/releases/tag/v0.3.0
