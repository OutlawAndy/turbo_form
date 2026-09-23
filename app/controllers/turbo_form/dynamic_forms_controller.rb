module TurboForm
  # Renders a form again from the state the browser currently has it in.
  #
  # Nothing here is saved. The form's object is rebuilt only so the template can
  # ask it what the form should now look like, which is why the parameters are
  # taken whole: narrowing them would only make the re-rendered form disagree
  # with what the user actually typed.
  class DynamicFormsController < TurboForm.parent_controller.constantize
    rescue_from TurboForm::Signature::Invalid do
      head :bad_request
    end

    around_action :discard_writes
    before_action :build_resource
    before_action { TurboForm.before_render&.call(self, @resource) }

    def update
      render template: signature.template_for(@resource), formats: :turbo_stream
    end

    private
      def build_resource
        @resource = signature.rebuild(form_params)
      end

      # Assigning to a saved record is not always inert: Active Record saves
      # `has_many` writers and `*_ids=` on the spot.
      def discard_writes
        return yield unless defined?(ActiveRecord::Base) && signature.model < ActiveRecord::Base

        signature.model.transaction do
          yield
          raise ActiveRecord::Rollback
        end
      end

      def signature
        @signature ||= TurboForm::Signature.verify(params[:signature])
      end

      def form_params
        params.fetch(signature.scope, {}).permit!
      end
  end
end
