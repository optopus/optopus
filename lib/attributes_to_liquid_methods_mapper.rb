module AttributesToLiquidMethodsMapper
  def self.included(base)
    base.class_eval do
      base.attribute_names.each do |attribute|
        liquid_methods attribute.to_sym
      end
    end
  end
end
