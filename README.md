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

`dynamic: true` makes the form dynamic. When a trigger fires, the gem renders a
template named `dynamic_form`, looked up just as the controller that rendered
the form would look up one of its own views:

- A form rendered by `WidgetsController` gets
  `widgets/dynamic_form.turbo_stream.erb`.
- If that doesn't exist, lookup follows controller inheritance, ending at
  `application/dynamic_form.turbo_stream.erb`.
- Partials resolve the same way, so `render "fields"` inside the template finds
  `widgets/_fields`, just as it would in the form itself.

To render a different template, pass its name instead of `true`:

```erb
<%= form_for @widget, dynamic: "shared/refresh_widget" %>
```

### `dynamic_trigger:` on a field

```erb
<%= f.text_field :name, dynamic_trigger: true %>       <%# on the default event %>
<%= f.text_field :name, dynamic_trigger: :blur %>      <%# on a named event %>
```

`true` lets Stimulus pick the element's natural event: `change` for a select or
checkbox, `input` for a text field, `click` for a button. Name an event when you
want something else — `:blur` on text fields is usually what you want, since the
default fires on every keystroke.

#### Sending the form somewhere else

A trigger can answer to a different endpoint than its own form, and can add to
what the form sends:

```erb
<%= f.button "Run", type: "button", dynamic_trigger: {
      event: :click,
      url: formula_preview_widgets_path,
      params: { attribute: :rafter_count }
    } %>
```

`url:` replaces the form's own endpoint for that one trigger; everything else on
the form keeps using the form's. `params:` are appended to the submitted form
data, so one endpoint can tell which of several triggers asked. Both are
optional, and either can be given without the other.

That endpoint is yours, not the gem's — it's an ordinary action rendering an
ordinary turbo_stream template, so the whole form arrives as `params` under its
usual scope. Use it when one form feeds several actions: a dozen fields that
each preview themselves, or a select that belongs to a nested form with its own
controller.

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
2. rebuilds the form's object and assigns them to it — an edit form's record is
   found again by id, and a new form's object is rebuilt from the attributes it
   was built with (a parent's foreign key from `@order.line_items.new`, say) before
   the submitted ones are applied,
3. assigns it to `@resource`,
4. runs `TurboForm.before_render` inside the controller with the resource, if one is set,
5. renders the turbo_stream template.

Nothing is persisted. `@resource` exists to be asked what the form should now
look like, not to be saved — and since Active Record saves some assignments on
the spot (`has_many` writers, `*_ids=`), an Active Record resource is rebuilt
inside a transaction that is always rolled back.

The signature covers the class name, the parameter scope, the template, the view
paths the form was rendered under, and the record's id or starting attributes. It is signed because the endpoint
constantizes, loads and renders what it names; none of that may come from the
browser unverified. It is not encrypted, so those starting attributes are
readable in the page, as the form itself is.

## Configuration

```ruby
# config/initializers/turbo_form.rb

# The endpoint inherits from this, so your authentication applies to it. Point
# it at a narrower controller when that inheritance brings something the
# endpoint shouldn't have.
TurboForm.parent_controller = "ApplicationController"

# Draw the route yourself instead.
TurboForm.draw_routes = false

# Run something before the render. See below.
TurboForm.before_render = ->(resource) { }
```

### `before_render`

The endpoint is a controller you never wrote, inheriting filters written for
controllers that save things. `before_render` is where you get to treat it like
one of your own: it runs in a `before_action`, after the signature is verified
and the resource is built, and is handed that resource. It runs *inside* the
controller, so its protected helpers — Pundit's among them — are in reach.

Satisfy a filter the endpoint can't — the most common need, since nothing here
is authorized because nothing here is saved:

```ruby
# Pundit's after_action :verify_authorized
TurboForm.before_render = ->(resource) { skip_authorization }

# Action Policy's verify_authorized
TurboForm.before_render = ->(resource) { skip_verify_authorized! }
```

Or authorize it for real, if re-rendering a form is something you'd rather gate.
Name the query explicitly: the endpoint's action is `update`, which is not the
permission you mean.

```ruby
# Pundit
TurboForm.before_render = ->(resource) { authorize resource, :edit? }

# Action Policy
TurboForm.before_render = ->(resource) { authorize! resource, to: :edit? }

# CanCanCan -- this also satisfies `check_authorization`, which has no runtime skip
TurboForm.before_render = ->(resource) { authorize! :edit, resource }
```

Raising works the way it does in any `before_action`: your
`rescue_from`s catch it, since the endpoint inherits them too. Rendering or
redirecting halts the chain as usual.

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
debouncing, no request cancellation and no loading state. When you need those, write the action by hand — that path is still open,
and this gem doesn't stand in front of it.

## License

MIT.
