module TurboForm
  # Included into the host's ApplicationController, where its public method
  # counts as an action -- Rails treats every public method of the abstract
  # ActionController::Base as internal, so it can't live there. Only a resource
  # drawn with TurboForm::Routes routes to it.
  #
  # Leans on the scaffold's conventions: the namesake action builds
  # `@<resource>`, `<resource>_params` permits the form, and the namesake's own
  # template renders it.
  module Controller
    def dynamic_form
      discarding_writes do
        process_action(dynamic_action)
        turbo_form_resource.extend(TurboForm::Resource)
        turbo_form_resource.assign_attributes(turbo_form_resource_params)
        @_response_body = nil
        render dynamic_action
      end
    end

    private
    def turbo_form_resource = instance_variable_get(:"@#{turbo_form_resource_name}")
    def turbo_form_resource_params = send(:"#{turbo_form_resource_name}_params")
    def turbo_form_resource_name = controller_name.singularize
    def dynamic_action = params.require(:dynamic_action)

    # Active Record saves `has_many` writers and `*_ids=` on assignment, and
    # this action exists only to render.
    def discarding_writes
      return yield unless defined?(ActiveRecord::Base)

      ActiveRecord::Base.transaction do
        yield
        raise ActiveRecord::Rollback
      end
    end
  end

  module Resource
    def assign_attributes(params)
      super(params)
      becomes!(sti_class_for(self[inheritance_column])) if can_become?
      self
    end

    def can_become?
      inheritance_column.present? && self[inheritance_column].present?
    end

    def sti_class_for(type)
      self.class.sti_class_for(type) if self.class.respond_to?(:sti_class_for)
    end

    def inheritance_column
      self.class.inheritance_column if self.class.respond_to?(:inheritance_column)
    end
  end
end
