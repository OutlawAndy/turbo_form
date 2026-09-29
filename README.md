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

It imports the script into `app/javascript/application.js`, adding the npm
package first if your app bundles with esbuild, Vite, Bun or webpack; see
[JavaScript](#javascript) for doing that by hand.

The engine does the rest. Draw the `:turbo_form` route concern on each resource
with a dynamic form:

```ruby
resources :widgets, concerns: :turbo_form
```

It draws a PATCH beside whichever of `new` and `edit` the resource has, so
`resources :widgets, only: %i[new create], concerns: :turbo_form` gets only the
one for `new`. Every controller inheriting from `ActionController::Base` already
knows how to answer it.

## The options

### `dynamic:` on the form

`dynamic: true` makes the form dynamic: a trigger sends it to the `new` or `edit`
page of its model — `edit` once the record is saved — which is where
the route concern listens.

### `dynamic_trigger:` on a field

```erb
<%= f.text_field :name, dynamic_trigger: true %>       <%# on the default event %>
<%= f.text_field :name, dynamic_trigger: :blur %>      <%# on a named event %>
```

`true` picks the element's natural event: `change` for a select, `click` for a
button, `input` for everything else. Name an event when you want
something else — `:blur` on text fields is usually what you want, since the
default fires on every keystroke. Any event name works, including custom ones
dispatched by other Stimulus controllers — `dynamic_trigger: "autocomplete:selected"`
— as long as the event is dispatched on the field or bubbles up from inside it.

Works on every Rails field helper and on `f.submit` and `f.button`, including
the select and date families where Rails keeps HTML attributes in a separate hash:

```erb
<%= f.collection_select :category_id, Category.all, :id, :name, dynamic_trigger: true %>
```

### `dynamic_action:` on a field

```erb
<%= f.select :flavor, @widget.flavors, {}, dynamic_action: summary_widgets_path %>
<%= f.text_field :zip, dynamic_action: lookup_path(form: "widget"), dynamic_trigger: :blur %>
<%= f.button "Swap", type: "button", dynamic_action: [:swap, @estimate] %>
```

For when the page's own render isn't the answer: the trigger PATCHes the whole
form to that URL instead, asks for a Turbo Stream, and renders the stream it
gets back, whatever its status, so a `422` of errors renders too. The URL is
anything `url_for` takes. The action and its `.turbo_stream` template are yours. Nothing is assigned or
rolled back for you, and the form doesn't need `dynamic: true`. It triggers on
the field's default event unless `dynamic_trigger:` names one, and counts toward
`expect_dynamic_form_request`.

### With SimpleForm

turbo_form builds on `ActionView::Helpers::FormBuilder`, which SimpleForm
inherits from, so it works without SimpleForm being involved at all:

```slim
= simple_form_for @widget, dynamic: true do |f|
  = f.input :category, input_html: { dynamic_trigger: true }
```

## What a trigger does

A trigger PATCHes the whole form to its own page — `/widgets/new` or
`/widgets/:id/edit` — which the route concern sends to that page's own action.
The request:

1. runs `new` or `edit` as an ordinary visit would, callbacks and all, building
   `@widget` the way it always does — found by id, built from a parent,
   whatever it does,
2. assigns `widget_params` to it,
3. renders the page's own template,

all inside a database transaction that is always rolled back.

Because the values are assigned in the controller, before anything renders, the
whole page sees what was typed — the layout, the template above the form, and
the form itself.

The rollback is there because Active Record saves some assignments on the spot
(`has_many` writers, `*_ids=`). A trigger exists to render, so nothing it does is
kept — including anything else the action or its callbacks write.

### The conventions it leans on

turbo_form knows nothing about your resource beyond its controller's name.
For a `WidgetsController`:

- `new` and `edit` set `@widget`,
- `widget_params` permits the form's fields — the same method `create` and
  `update` already use, so a trigger assigns nothing a save wouldn't,
- `new` and `edit` render their own template, implicitly or with `render`
  themselves — `render layout: 'panel'` is fine. The values are assigned just
  before it renders; an action that redirects still redirects.

### Switching an STI subclass

When the submitted values include the inheritance column, the object is switched
to the subclass it names, with `becomes`, before assigning — so a `type` select
can turn a `Gizmo` into a `Doohickey` and the rest of the page answers as one.
Give the form its base class's scope (`scope: :gadget`) so the switched object
reads and posts under the same name, and permit `type` in the params method.

### Telling a trigger from a visit

`turbo_form_render?` is true while a trigger's request is rendering, in the
controller and in views, so a layout can leave alone what an ordinary visit
would set up — a modal that animates open on arrival, say:

```erb
<div data-open-on-connect="<%= !turbo_form_render? %>">
```

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
  `dynamic_action:` is the way out, at the cost of writing the action and its
  stream.
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
