module Optopus
  class App
    get '/' do
      liquid :index, :locals => { :title => 'hi', :appliances => Appliance.all }
    end
  end
end
