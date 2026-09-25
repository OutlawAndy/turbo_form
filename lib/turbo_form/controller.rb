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
      namesake = params.require(:turbo_form)
      ivar = :"@#{turbo_form_resource}"

      discarding_writes do
        send(namesake)
        instance_variable_set(ivar, turbo_form_assign(instance_variable_get(ivar), send(:"#{turbo_form_resource}_params")))
        render namesake
      end
    end

    private
      def turbo_form_resource = controller_name.singularize

      # Switches to the STI subclass the submitted `type` names before assigning,
      # so nested records land on the object that is kept.
      def turbo_form_assign(object, submitted)
        turbo_form_retype(object, submitted).tap { |record| record.assign_attributes(submitted) }
      end

      def turbo_form_retype(object, submitted)
        column = object.class.try(:inheritance_column)
        return object unless column && submitted.key?(column)

        subclass = object.class.base_class.new(column => submitted[column]).class
        object.instance_of?(subclass) ? object : object.becomes(subclass)
      end

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
end
