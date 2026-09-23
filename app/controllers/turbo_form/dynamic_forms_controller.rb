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
    before_action { instance_exec(@resource, &TurboForm.before_render) if TurboForm.before_render }

    def update
      render signature.template || "dynamic_form", formats: :turbo_stream
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

      # Renders as if it were the controller that rendered the form, so the
      # template's relative partials resolve the way the form's own did.
      #
      # Read while the lookup context is built, before `rescue_from` is in play,
      # so a bad signature falls through here and is answered by the action.
      def _prefixes
        signature.prefixes
      rescue TurboForm::Signature::Invalid
        super
      end

      def signature
        @signature ||= TurboForm::Signature.verify(params[:signature])
      end

      def form_params
        params.fetch(signature.scope, {}).permit!
      end
  end
end
