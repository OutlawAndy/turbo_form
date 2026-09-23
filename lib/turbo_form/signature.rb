module TurboForm
  # A tamper-proof description of a dynamic form, carried in the URL the browser
  # posts back to.
  #
  # It is signed because the endpoint acts on every word of it: `model_name` gets
  # constantized and instantiated, `template` gets rendered. Neither may come
  # from the client unverified.
  #
  # `prefixes` are the view paths the form was rendered under, so the endpoint
  # can find its template and partials the way the form's own controller would.
  #
  # It also says where the form's object came from, so the endpoint can rebuild
  # that object rather than a blank one: the `id` of a saved record, or the
  # `seed` of attributes an unsaved one already had -- the `tank_id` of
  # `@tank.rings.new` -- which the form itself may never submit.
  class Signature
    class Invalid < StandardError; end

    def self.verify(token)
      payload = TurboForm.verifier.verified(token.to_s)
      raise Invalid, "not a signature this application generated" unless payload

      new(**payload.symbolize_keys)
    end

    attr_reader :model_name, :scope, :template, :prefixes, :id, :seed

    def initialize(model_name:, scope:, template: nil, prefixes: [], id: nil, seed: {})
      @model_name = model_name
      @scope = scope
      @template = template
      @prefixes = prefixes
      @id = id
      @seed = seed
    end

    def model = model_name.constantize

    # The form's object as the user now has it. A new one is built in a single
    # step so the submitted `type` still picks an STI subclass.
    def rebuild(params)
      return model.new(seed.merge(params.to_h)) unless id

      model.find(id).tap { |resource| resource.assign_attributes(params) }
    end

    def to_s
      TurboForm.verifier.generate({ model_name:, scope:, template:, prefixes:, id:, seed: })
    end
    alias to_param to_s
  end
end
