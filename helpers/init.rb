module Optopus::AppHelpers ; end

require_relative 'menu'
require_relative 'main'

module Optopus
  class App
    class ParamError < StandardError; end

    # Because of Sinatra's anonymous shorthand for helpers (helpers do end),
    # we can't test our helpers. As a workaround, the easy way to do this
    # is to create modules.
    #
    # see https://github.com/padrino/padrino-framework/issues/930
    helpers Optopus::AppHelpers::Menu
    helpers Optopus::AppHelpers::Main
  end
end
