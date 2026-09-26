module TurboForm
  # Included into the host's ApplicationController. A request that
  # TurboForm::Routes marks runs `new` or `edit` as usual, callbacks and all,
  # then assigns the form to what the action built just before the implicit
  # render.
  #
  # Leans on the scaffold's conventions: the action builds `@<resource>`,
  # `<resource>_params` permits the form, and the action leaves rendering to Rails.
  module Controller
    private
    def process_action(...)
      dynamic_form? ? discarding_writes { super } : super
    end

    def default_render
      dynamic_form_assignment if dynamic_form?
      super
    end

    def dynamic_form_assignment
      resource = turbo_form_resource.extend(TurboForm::Resource).dynamic_assign(turbo_form_resource_params)
      instance_variable_set(:"@#{turbo_form_resource_name}", resource)
    end

    def dynamic_form? = request.path_parameters[:dynamic_form]
    def turbo_form_resource = instance_variable_get(:"@#{turbo_form_resource_name}")
    def turbo_form_resource_params = send(:"#{turbo_form_resource_name}_params")
    def turbo_form_resource_name = controller_name.singularize

    # Active Record saves `has_many` writers and `*_ids=` on assignment, and
    # this request exists only to render.
    def discarding_writes
      return yield unless defined?(ActiveRecord::Base)

      ActiveRecord::Base.transaction do
        yield
        raise ActiveRecord::Rollback
      end
    end
  end

  # Switches to the STI subclass the submitted `type` names before assigning, so
  # nested records land on the object that is kept -- which is returned.
  module Resource
    def dynamic_assign(params)
      retype(params).tap { it.assign_attributes(params) }
    end

    private
    def retype(params)
      type = inheritance_column && params[inheritance_column]
      return self if type.blank?

      subclass = self.class.sti_class_for(type)
      instance_of?(subclass) ? self : becomes!(subclass)
    end

    def inheritance_column = self.class.try(:inheritance_column)
  end
end
