# turbo_form

Dynamic forms for Rails, by convention.

A form that needs to change as it is filled in — a dependent dropdown, a section
that appears once you pick a type — usually costs you a route, a controller
action, a Stimulus controller and some wiring. This gem asks for two words
instead:

```erb
<%= form_for @widget, dynamic: true do |f| %>
  <%= f.select :category, @widget.categories, {}, dynamic_trigger: true %>
  <%= f.select :flavor, @widget.flavors %>
<% end %>
```

Pick a category and the page reloads with the form as it currently stands. The
form assigns what was typed to `@widget` before its fields render, so
`@widget.flavors` answers for the category just picked. Turbo morphs the page in
place, so focus, scroll and everything else typed survive the reload.

That's the whole feature. No route, no controller action, no template, no
JavaScript. The page is rendered by its own controller, so its authentication,
authorization and partials are the ones it always had.

## Installation

```ruby
gem "turbo_form"
```

On a stock Rails app — Propshaft, importmap-rails, stimulus-rails — the Stimulus
controller registers itself and there is nothing to generate. If your app
bundles with esbuild, Vite, Bun or webpack:

```bash
rails generate turbo_form:install
```

See [JavaScript](#javascript) for what that does and how to do it by hand.

## The two options

### `dynamic:` on the form

`dynamic: true` makes the form dynamic: on a reload, it assigns the submitted
values under its scope to its object, via `assign_attributes`, before any field
renders.

### `dynamic_trigger:` on a field

```erb
<%= f.text_field :name, dynamic_trigger: true %>       <%# on the default event %>
<%= f.text_field :name, dynamic_trigger: :blur %>      <%# on a named event %>
```

`true` lets Stimulus pick the element's natural event: `change` for a select or
checkbox, `input` for a text field, `click` for a button. Name an event when you
want something else — `:blur` on text fields is usually what you want, since the
default fires on every keystroke.

Works on every Rails field helper, including the select and date families where
Rails keeps HTML attributes in a separate hash:

```erb
<%= f.collection_select :category_id, Category.all, :id, :name, dynamic_trigger: true %>
```

### With SimpleForm

turbo_form builds on `ActionView::Helpers::FormBuilder`, which SimpleForm
inherits from, so it works without SimpleForm being involved at all:

```slim
= simple_form_for @widget, dynamic: true do |f|
  = f.input :category, input_html: { dynamic_trigger: true }
```

## What a reload does

A trigger visits the page's own URL with the form's fields in the query string,
leaving out the authenticity token and `_method`, and marks the request with an
`X-Turbo-Form` header. On the server:

1. the page's controller runs as it would for any visit, building `@widget` the
   way it always does — found by id, built from a parent, whatever it does,
2. the form assigns the submitted values to that object as it starts to render,
3. the whole request runs inside a database transaction that is always rolled
   back.

Only a request carrying the header is assigned anything. A plain link can't set
a header, and another origin can't without a CORS preflight, so a hand-crafted
URL with form values in it renders the page as if they weren't there.

The rollback is there because Active Record saves some assignments on the spot
(`has_many` writers, `*_ids=`). A reload exists to render, so nothing it does is
kept — including anything else the action writes.

### Needing the values before the form

The form assigns as it starts to render, so everything from the form down — and
the layout, which Rails renders after the template — sees what was typed. The
controller, and anything in the template above the form, sees the object as it
was built. When those need it too, assign in the action:

```ruby
def new
  @widget = turbo_form_assign(Widget.new)
end
```

`turbo_form_assign` returns the object, assigns only on a reload, and takes
`scope:` when the form's scope isn't the object's param key. The form assigns
the same values again when it renders, which changes nothing.

### After a failed save

Rendering `:new` or `:edit` with `422` after a failed save leaves the browser on
the form's own URL, since Turbo renders it without touching history — so a
trigger reloads the right page. The reload builds a fresh object that has not
been validated, so the error messages go away.

## JavaScript

**importmap-rails** — nothing to do. The engine pins its controller as
`controllers/turbo_form_controller`, which the `eagerLoadControllersFrom` /
`lazyLoadControllersFrom` in a stock `app/javascript/controllers/index.js`
registers as `turbo-form` on its own.

If you hand-wrote that file, register it yourself:

```js
import TurboFormController from "controllers/turbo_form_controller"
application.register("turbo-form", TurboFormController)
```

**esbuild, Vite, Bun, webpack** — there is no sweep to pick the controller up,
so the package has to be installed alongside the gem, at the same version, and
registered. `rails generate turbo_form:install` does both: it adds the package
with whichever manager your lockfile names, and writes

```js
// app/javascript/controllers/turbo_form_controller.js
import TurboFormController from "@rolemodel/turbo-form"

export default TurboFormController
```

Registering by *filename* rather than by appending to
`app/javascript/controllers/index.js` is deliberate. That file is regenerated
from the contents of the directory every time `rails generate stimulus` runs, so
a registration appended to it lasts until the next controller you generate. A
file named `turbo_form_controller.js` is picked up by that same regeneration and
registered as `turbo-form`, every time.

To do it by hand, write that file yourself and run `rails stimulus:manifest:update`.

### Testing against it

A reload is a round trip, so the line after a trigger is racing it. Wrap the
trigger and the wait comes with it:

```ruby
expect_dynamic_form_request { select "Bourbon", from: "Category" }
select "Barrel Aged", from: "Flavor"
```

`expect_dynamic_form_request` is available in system tests with nothing to
require or include — Minitest and RSpec both. It waits on a count of
completed reloads kept on `<html>` rather than on the fields that came back, so
it doesn't care what the reload changed.

## What this deliberately doesn't do

It handles the common case well and gets out of the way otherwise.

- **No debouncing, request cancellation or loading state.** Write the action by
  hand when you need those — that path is still open.
- **The form rides in the URL.** Very large forms can hit URL length limits,
  file inputs are left out, and what was typed lands in browser history and any
  access log outside Rails' own parameter filtering.
- **Only the primary database is rolled back**, and only writes: jobs enqueued
  or mail sent during a reload still happen. A streamed response renders after
  the transaction has closed.
- **An STI edit form doesn't change class.** Assigning `type` to a saved record
  changes the column, not the Ruby class the form asks.
- **A form with Turbo turned off** reloads whatever URL a failed save left it on.

## License

MIT.
