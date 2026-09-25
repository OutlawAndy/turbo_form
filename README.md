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

Pick a category and the form is sent to the page it is on. That page's own
action builds `@widget`, the form's values are assigned to it, and the page's
own template renders it — so `@widget.flavors` answers for the category just
picked. Turbo morphs the page in place, so focus, scroll and everything else
typed survive.

No new action, no template, no JavaScript to write. The page is rendered by its
own controller, so its authentication, authorization and partials are the ones
it always had.

## Installation

```ruby
gem "turbo_form"
```

Then run the installer:

```bash
rails generate turbo_form:install
```

It mixes the action into your ApplicationController and declares the route
concern:

```ruby
class ApplicationController < ActionController::Base
  include TurboForm::Controller
end
```

```ruby
concern :turbo_form, TurboForm::Routes
```

Draw the concern on each resource with a dynamic form — the installer leaves
which ones to you:

```ruby
resources :widgets, concerns: :turbo_form
```

It also imports the script into `app/javascript/application.js`, adding the npm
package first if your app bundles with esbuild, Vite, Bun or webpack; see
[JavaScript](#javascript) for doing that by hand.

## The two options

### `dynamic:` on the form

`dynamic: true` makes the form dynamic: a trigger sends it to the `new` or `edit`
page of its model — `edit` once the record is saved — which is where
`TurboForm::Routes` listens.

### `dynamic_trigger:` on a field

```erb
<%= f.text_field :name, dynamic_trigger: true %>       <%# on the default event %>
<%= f.text_field :name, dynamic_trigger: :blur %>      <%# on a named event %>
```

`true` picks the element's natural event: `change` for a select, `click` for a
submit button, `input` for everything else. Name an event when you want
something else — `:blur` on text fields is usually what you want, since the
default fires on every keystroke. A named event is one of `:input`, `:change`,
`:blur` or `:click`.

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

## What a trigger does

A trigger PATCHes the whole form to its own page — `/widgets/new` or
`/widgets/:id/edit` — which the route concern sends to `dynamic_form`. That
action:

1. runs the page's own action (`new` or `edit`), building `@widget` the way it
   always does — found by id, built from a parent, whatever it does,
2. assigns `widget_params` to it,
3. renders the page's own template,

all inside a database transaction that is always rolled back.

Because the values are assigned in the controller, before anything renders, the
whole page sees what was typed — the layout, the template above the form, and
the form itself.

The rollback is there because Active Record saves some assignments on the spot
(`has_many` writers, `*_ids=`). A trigger exists to render, so nothing it does is
kept — including anything else the action writes.

### The conventions it leans on

`dynamic_form` knows nothing about your resource beyond its controller's name.
For a `WidgetsController`:

- `new` and `edit` set `@widget`,
- `widget_params` permits the form's fields — the same method `create` and
  `update` already use, so a trigger assigns nothing a save wouldn't,
- `new` and `edit` leave rendering to Rails. One that calls `render` or
  `redirect_to` itself raises `AbstractController::DoubleRenderError`.

### Switching an STI subclass

When the submitted values include the inheritance column, the object is switched
to the subclass it names, with `becomes`, before assigning — so a `type` select
can turn a `Gizmo` into a `Doohickey` and the rest of the page answers as one.
Give the form its base class's scope (`scope: :gadget`) so the switched object
reads and posts under the same name, and permit `type` in the params method.

### Inside a Turbo Frame

A form inside a `<turbo-frame>`, or one naming a frame with
`data-turbo-frame`, asks for that frame alone: the request carries the
`Turbo-Frame` header, turbo-rails renders without the layout, and only the frame
is morphed. A frame's own `target` is followed, and `_top` means the whole page,
as they do for Turbo. While the request is out, the form and its frame are `aria-busy`, and the
frame `busy`, the way Turbo marks a submission.

### After a failed save

A trigger sends the form to its model's `new` or `edit` page, not to whatever
URL the browser is on, so a trigger after rendering `:new` from a failed
`create` still reaches the right action. The object it builds is fresh and has
not been validated, so the error messages go away.

## JavaScript

There is no Stimulus controller to register. The script listens on the document
for triggers, so it only has to be imported once:

```js
// app/javascript/application.js
import "turbo_form"             // importmap-rails: the engine pins it
import "@rolemodel/turbo-form"  // esbuild, Vite, Bun, webpack
```

Bundled apps install the npm package alongside the gem, at the same version.
`rails generate turbo_form:install` does that with whichever package manager
your lockfile names, and adds the import.

To send a form from your own code, import `refresh`:

```js
import { refresh } from "turbo_form"

refresh(document.querySelector("form[data-turbo-form-url]"))
```

### Testing against it

A trigger is a round trip, so the line after it is racing it. Wrap the
trigger and the wait comes with it:

```ruby
expect_dynamic_form_request { select "Bourbon", from: "Category" }
select "Barrel Aged", from: "Flavor"
```

`expect_dynamic_form_request` is available in system tests with nothing to
require or include — Minitest and RSpec both. It waits on a count of
completed triggers kept on `<html>` rather than on the fields that came back, so
it doesn't care what the trigger changed.

## What this deliberately doesn't do

It handles the common case well and gets out of the way otherwise.

- **No debouncing, request cancellation or loading state** beyond `aria-busy`.
  Write the action by hand when you need those — that path is still open.
- **Resourceful pages only.** The form's URL comes from its model, so a page
  whose `new` or `edit` isn't the model's own route has nowhere to send it.
- **Not a Turbo form submission.** Turbo renders a form's response only when it
  redirects or fails, so the trigger fetches the form itself and hands the
  response to a Turbo visit. Turbo renders the page — its morph, render events,
  error page and progress bar — but there are no `turbo:submit-start`,
  `turbo:submit-end` or `turbo:before-fetch-request` events. A frame is morphed
  directly, without Turbo's frame render events.
- **Only the primary database is rolled back**, and only writes: jobs enqueued
  or mail sent during a trigger still happen.

## License

MIT.
