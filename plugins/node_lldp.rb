require 'optopus/plugin'
module Optopus
  module Plugin
    module NodeLLDP
      extend Optopus::Plugin
      plugin do
        register_partial :node, :node_lldp, :display => 'Network Connectivity'
      end

      template :node_lldp do
        view = Array.new
        view << "<% if @node.facts.include?('interfaces') %>"
        view << '<div class="page-header">'
        view << ' <h3>Network connectivity</h3>'
        view << ' <small>Data connected from lldp</small>'
        view << '</div>'
        view << '<table class="table table-striped table-bordered table-condensed">'
        view << ' <tbody>'
        view << "   <% @node.facts['interfaces'].split(',').each do |interface| %>"
        view << '   <% if @node.facts["lldp_#{interface}_chassis_name"] && @node.facts["lldp_#{interface}_port_descr"] %>'
        view << '   <tr>'
        view << '     <td style="width: 200px"><%= interface %></td>'
        view << '     <td>'
        view << '       <ul class="unstyled">'
        view << '         <li>switch: <%= @node.facts["lldp_#{interface}_chassis_name"].human_empty %></li>'
        view << '         <li>port: <%= @node.facts["lldp_#{interface}_port_descr"].human_empty %></li>'
        view << '         <li>vlan: <%= @node.facts["lldp_#{interface}_vlan"].human_empty %></td></li>'
        view << '       </ul>'
        view << '   </tr>'
        view << '   <% end %>'
        view << '   <% end %>'
        view << ' </tbody>'
        view << '</table>'
        view << '<% end %>'
        view.join("\n")
      end
    end
  end
end
