module TurboForm
  # Included into the host's ApplicationController. A request that
  # TurboForm::Routes marks runs `new` or `edit` as usual, callbacks and all,
  # then assigns the form to what the action built just before it renders --
  # implicitly, or with its own `render layout: 'panel'`.
  #
  # Leans on the scaffold's conventions: the action builds `@<resource>` and
  # `<resource>_params` permits the form.
  module Controller
    extend ActiveSupport::Concern

    included do
      helper_method :turbo_form_render?
    end

    # Public, as Rails' own is. ActionController::Base's public methods are never
    # actions, so this one isn't either.
    def render(...)
      dynamic_form_assignment if turbo_form_render?
      super
    end

    private
    # Whether this request is a trigger's re-render rather than a visit, for a
    # layout or template that should answer differently to one.
    def turbo_form_render? = request.path_parameters.key?(:dynamic_form)

    def process_action(...)
      turbo_form_render? ? discarding_writes { super } : super
    end

    def dynamic_form_assignment
      resource = turbo_form_resource.extend(TurboForm::Resource).dynamic_assign(turbo_form_resource_params)
      instance_variable_set(:"@#{turbo_form_resource_name}", resource)
    end

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
