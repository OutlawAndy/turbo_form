# turbo_form

Turbo-Stream backed dynamic forms for Rails, by convention.

A form that needs to change as it is filled in — a dependent dropdown, a section
that appears once you pick a type — usually costs you a route, a controller
action, a Stimulus controller and some wiring. This gem asks for two words
instead:

```erb
<%= form_for @widget, dynamic: true do |f| %>
  <%= f.select :category, @widget.categories, {}, dynamic_trigger: true %>

  <div id="flavor-field">
    <%= f.select :flavor, @widget.flavors %>
  </div>
<% end %>
```

Pick a category and the form is sent to the server as it currently stands. The
server rebuilds `@resource` from what you typed and renders
`app/views/widgets/dynamic_form.turbo_stream.erb`:

```erb
<%= fields model: @resource do |f| %>
  <%= turbo_stream.update "flavor-field" do %>
    <%= f.select :flavor, @resource.flavors %>
  <% end %>
<% end %>
```

That's the whole feature. No route, no controller, no JavaScript.

## Installation

```ruby
gem "turbo_form"
```

There is nothing to mount. On a stock Rails app — Propshaft, importmap-rails,
stimulus-rails — the Stimulus controller registers itself and there is nothing
to generate either. If your app bundles with esbuild, Vite, Bun or webpack:

```bash
rails generate turbo_form:install
```

See [JavaScript](#javascript) for what that does and how to do it by hand.

## The two options

### `dynamic:` on the form

`dynamic: true` wires the form up and points it at
`app/views/<resource dir>/dynamic_form.turbo_stream.*` — alongside the
resource's own partial, so `widgets/_widget` gets `widgets/dynamic_form`.

Pass a string to render something else instead:

```erb
<%= form_for @widget, dynamic: "shared/refresh_widget" %>
```

Works on `form_for` and `form_with` alike. Any template engine works — the
template is resolved the way every other Rails template is, so `.slim` and
`.haml` are fine.

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

## What the endpoint does

A `dynamic: true` form carries a signed description of itself to a single
endpoint the gem draws into your routes. Given a valid signature it:

1. permits the submitted parameters wholesale,
2. builds a **new, unsaved** instance of the form's class from them,
3. assigns it to `@resource`,
4. renders the turbo_stream template.

Nothing is persisted, and the resource is always freshly instantiated — even for
an edit form. `@resource` exists to be asked what the form should now look like,
not to be saved.

The signature covers the class name, the parameter scope and the template. It is
signed because the endpoint constantizes and renders what it names; none of that
may come from the browser unverified.

## Configuration

```ruby
# config/initializers/turbo_form.rb

# The endpoint inherits from this, so your authentication applies to it. If your
# ApplicationController enforces something the endpoint can't satisfy -- Pundit's
# `verify_authorized`, say -- point this at a controller that doesn't.
TurboForm.parent_controller = "ApplicationController"

# Draw the route yourself instead.
TurboForm.draw_routes = false
```

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

A re-render is a round trip, so the line after a trigger is racing it. Wrap the
trigger and the wait comes with it:

```ruby
expect_dynamic_form_request { select "Bourbon", from: "Category" }
select "Barrel Aged", from: "Flavor"
```

`expect_dynamic_form_request` is available in system tests with nothing to
require or include — Minitest and RSpec both. It waits on the controller's
count of completed round trips rather than on the fields that came back, so it
doesn't care what the response changed. Scope it with Capybara's `within` when
a page carries more than one dynamic form.

## What this deliberately doesn't do

It handles the common case well and gets out of the way otherwise. There is no
debouncing, no request cancellation, no loading state, no per-element URL
override, and no hook for loading an existing record instead of building a new
one. When you need those, write the action by hand — that path is still open,
and this gem doesn't stand in front of it.

## License

MIT.
