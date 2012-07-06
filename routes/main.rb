module Optopus
  class App
    get '/' do
      liquid :index, :locals => { :title => 'hi', :appliances => Optopus::Appliance.all }
    end
  end
end
