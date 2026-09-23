class ApplicationController < ActionController::Base
  protected
    # Protected, as Pundit's `authorize` is: reachable only from inside.
    def gatekeep(widget)
      head :forbidden unless widget.category == "fruit"
    end
end
