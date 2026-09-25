module TurboForm
  # A dynamic trigger reloads its page with this header set. Only a request
  # carrying it has its form's state assigned, and only such a request has its
  # writes discarded -- one predicate for both, so the one can't happen without
  # the other. A plain link can't set a header, and a cross-origin page can't
  # without a CORS preflight, so a crafted URL assigns nothing.
  module Reload
    HEADER = "X-Turbo-Form"

    def self.requested?(request) = request&.headers&.key?(HEADER)

    # Answers with the object the form should now render, which is a different
    # one when the submitted `type` picks another STI subclass.
    def self.assign(object, submitted)
      return object unless submitted.is_a?(ActionController::Parameters)

      retype(object, submitted).tap { |record| record.assign_attributes(submitted.permit!) }
    end

    # Let `new` pick the subclass by Active Record's own STI rules, and switch
    # before assigning so nested records land on the object that is kept.
    # `becomes` shares its attributes with the original, so whoever still holds
    # that one sees the same values, if not the subclass's behaviour.
    def self.retype(object, submitted)
      column = object.class.try(:inheritance_column)
      return object unless column && submitted.key?(column)

      subclass = object.class.base_class.new(column => submitted[column]).class
      object.instance_of?(subclass) ? object : object.becomes(subclass)
    end

    # Included into ActionController::Base, for an action that needs the form's
    # state before the form itself is rendered:
    #
    #   @widget = turbo_form_assign(Widget.new)
    #
    # The form assigns the same state again when it renders, which changes
    # nothing. Keep what it returns: that is the switched object when the form
    # picked another STI subclass.
    module Controller
      private
        def turbo_form_assign(object, scope: object.model_name.param_key)
          return object unless TurboForm::Reload.requested?(request)

          TurboForm::Reload.assign(object, params[scope])
        end
    end

    # Assigning to a saved record is not always inert -- Active Record saves
    # `has_many` writers and `*_ids=` on the spot -- and a reload exists only to
    # render, so nothing it does is kept.
    class Middleware
      def initialize(app) = @app = app

      def call(env)
        return @app.call(env) unless defined?(ActiveRecord::Base) && Reload.requested?(ActionDispatch::Request.new(env))

        response = nil
        ActiveRecord::Base.transaction do
          # ponytail: a streamed body renders after this returns, outside the transaction
          response = @app.call(env)
          raise ActiveRecord::Rollback
        end
        response
      end
    end
  end
end
