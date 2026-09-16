# Drawn straight into the host's route set so that installing the gem is the
# whole installation -- there is nothing to mount. Set `TurboForm.draw_routes`
# to false to take that over.
#
# PATCH rather than POST for two reasons: whole forms outgrow a query string,
# and an edit form's `_method=patch` hidden field would make Rack rewrite a POST
# out from under us.
Rails.application.routes.draw do
  patch "/turbo_form/:signature" => "turbo_form/dynamic_forms#update", as: :turbo_form
end if TurboForm.draw_routes
