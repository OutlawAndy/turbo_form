module TurboForm
  # Renders a form again from the state the browser currently has it in.
  #
  # Nothing here is saved. The resource is rebuilt only so the template can ask
  # it what the form should now look like, which is why the parameters are taken
  # whole: narrowing them would only make the re-rendered form disagree with what
  # the user actually typed.
  class DynamicFormsController < TurboForm.parent_controller.constantize
    rescue_from TurboForm::Signature::Invalid do
      head :bad_request
    end

    def update
      @resource = signature.model.new(form_params)

      render template: signature.template_for(@resource), formats: :turbo_stream
    end

    private
      def signature
        @signature ||= TurboForm::Signature.verify(params[:signature])
      end

      def form_params
        params.fetch(signature.scope, {}).permit!
      end
  end
end
