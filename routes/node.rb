module Optopus
  class App
    helpers do
      def display_pod_link(node)
        node.pod ? node.pod.to_link : node.pod.human_empty
      end
    end

    get '/nodes' do
      subnav_from_locations
      erb :nodes
    end

    get '/nodes/new' do
      @nodes = Optopus::Node.where('created_at > ?', 7.days.ago).order('created_at DESC')
      erb :new_nodes
    end

    get '/nodes/dead' do
      @nodes = Optopus::Node.inactive
      erb :dead_nodes
    end

    get '/node/:hostname' do
      @subnav = [ { :id => 'general', :name => 'General' } ]
      @subnav += node_partials.inject([]) { |s,p| s << { :id => html_id(p[:template].to_s), :name => p[:display] }; s }
      @subnav << { :id => 'facts', :name => 'Facts' }
      @node = Optopus::Node.where(:hostname => params[:hostname]).first
      flash[:error] = "This node does not exist." if @node.nil?
      erb :node
    end

    get '/node/:hostname/fetch-motd' do
      @node = Optopus::Node.where(:hostname => params[:hostname]).first
      erb :node_motd, :layout => false
    end

    get '/node/:id/comments' do
      @node = Optopus::Node.where(:id => params[:id]).first
      erb :comments
    end

    get '/node/:id/addcomment' do
      @node = Optopus::Node.where(:id => params[:id]).first
      erb :addcomment
    end

    post '/node/:id/comment/add' do
      begin
      node = Optopus::Node.where(:id => params[:id]).first
        commenttext = params[:commenttext]
        node.node_comments.create!({:comment => commenttext})
        redirect back
      rescue Exception => e 
        handle_error(e)
      end
    end

    delete '/node/:id/comment/delete/:commentid' do
      begin
        node = Optopus::Node.where(:id => params[:id]).first
        node.node_comments.where(:id => params[:commentid]).first.destroy
        redirect back
      rescue Exception => e 
        handle_error(e)
      end
    end

    delete '/node/:id', :auth => :admin do
      node = Optopus::Node.where(:id => params[:id]).first
      begin
        node.destroy
        flash[:success] = "Deleted #{node.hostname} successfully!"
        register_event "{{ references.user.to_link }} deleted #{node.hostname}", :type => 'node_deleted'
        redirect '/'
      rescue Exception => e
        handle_error(e)
      end
    end

    # assign a node to a pod
    post '/node/:id/pod', :auth => :admin do
      node = Optopus::Node.where(:id => params[:id]).first
      begin
        raise "Node '#{params[:id]}' does not exists." if node.nil?
        validate_param_presence 'pod-id'
        pod = node.possible_pods.find_by_id(params['pod-id'])
        raise 'invalid pod ID for this node' if pod.nil?
        node.pod = pod
        node.save!
        flash[:success] = "Assigned #{node.hostname} to the pod #{pod.name} successfully!"
        register_event "{{ references.user.to_link }} assigned #{node.hostname} to the pod #{pod.name}", :type => 'pod'
        redirect back
      rescue Exception => e
        handle_error(e)
      end
    end

    # mark node as dead
    post '/node/:id/inactive', :auth => :admin do
      node = Optopus::Node.where(:id => params[:id]).first
      begin
        raise "Node '#{params[:id]}' does not exists." if node.nil?
        node.active = false
        node.save!
        flash[:success] = "Marked #{node.hostname} as dead successfully!"
        register_event "{{ references.user.to_link }} marked #{node.hostname} as dead", :type => 'node_inactive'
        redirect back
      rescue Exception => e
        handle_error(e)
      end
    end

    # post a single key => value
    post '/node/:id/property/:key/:value' do
      node = Optopus::Node.where(:id => params[:id]).first
      begin
        raise "Node '#{params[:id]}' does not exist." if node.nil?
        node.properties[params[:key]] = params[:value]
        node.save!
      rescue Exception => e
        handle_error(e)
      end
    end

    # post multiple key => values via json body
    post '/node/:id/properties' do
      node = Optopus::Node.where(:id => params[:id]).first
      begin
        raise "Node '#{params[:id]}' does not exist." if node.nil?
        properties = JSON.parse(request.body.read)
        node.properties.merge!(properties)
        node.save!
      rescue Exception => e
        handle_error(e)
      end
    end

    get '/node/:id/properties' do
      node = Optopus::Node.where(:id => params[:id]).first
      begin
        raise "Node '#{params[:id]}' does not exist." if node.nil?
        case request.content_type
        when 'application/json'
          body(node.properties.to_json)
        else
          # TODO: implement erb template for viewing keys
          raise "Route not implemented."
        end
      rescue Exception => e
        handle_error(e)
      end
    end

    get '/node/:id/property/:key' do
      node = Optopus::Node.where(:id => params[:id]).first
      begin
        raise "Node '#{params[:id]}' does not exist." if node.nil?
        content_type :json
        body({ params[:key] => node.properties[params[:key]] }.to_json)
      rescue Exception => e
        handle_error(e)
      end
    end
  end
end
