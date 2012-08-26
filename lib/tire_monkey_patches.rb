module Tire
  module Model
    module Search
      module Loader
        # The loader functionality built into tire seems busted, at least in the setup
        # used by Optopus. The built in method uses self.class.find, which tries to use 
        # Tire::Results::Item.find raising a no method error.
        #
        # To get around this I have to search through each model and look for a match
        # on self._type before running the find method.
        #
        # See: https://github.com/karmi/tire/issues/435
        def load(options=nil)
          Optopus::Models.list.each do |model|
            if model.model_name.underscore == self._type
              return options ? model.find(self.id, options) : model.find(self.id)
            end
          end
          nil
        end
      end
    end
  end
end
