module TurboForm
  # A dynamic trigger reloads its page with this header set. Only a request
  # carrying it has its form's state assigned, and only such a request has its
  # writes discarded -- one predicate for both, so the one can't happen without
  # the other. A plain link can't set a header, and a cross-origin page can't
  # without a CORS preflight, so a crafted URL assigns nothing.
  module Reload
    HEADER = "X-Turbo-Form"

    def self.requested?(request) = request&.headers&.key?(HEADER) || false

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
