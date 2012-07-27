module Optopus
  class App
    get '/nodes' do
      subnav_from_locations
      erb :nodes
    end

    get '/node/:uuid' do
      @subnav = [ { :id => 'general', :name => 'General' } ]
      @subnav += node_partials.inject([]) { |s,p| s << { :id => html_id(p[:template].to_s), :name => p[:display] }; s }
      @node = Optopus::Node.where(:uuid => params[:uuid]).first
      flash[:error] = "This node does not exist." if @node.nil?
      erb :node
    end
  end
end
