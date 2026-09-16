# Keyed as `controllers/..._controller` so the stock
# `eagerLoadControllersFrom("controllers", application)` in a Rails app finds it
# and registers it as `turbo-form`, with nothing asked of the host. The asset
# name is distinct so the host's own app/javascript/controllers can't shadow it.
pin "controllers/turbo_form_controller", to: "turbo_form.js"
