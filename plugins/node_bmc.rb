require 'optopus/plugin'
module Optopus
  module Plugin
    module NodeBMC
      extend Optopus::Plugin
      plugin do
        register_partial :node, :node_bmc, :display => 'Out of Band'
      end

      template :node_bmc do
        view = Array.new
        view << '<div class="page-header">'
        view << ' <h3>Out of band management</h3>'
        view << ' <small>Data collected via ipmitool</small>'
        view << '</div>'
        view << '<table class="table table-striped table-bordered table-condensed">'
        view << ' <tbody>'
        view << '   <tr>'
        view << '     <td style="width: 200px">BMC IP Address</td>'
        view << "     <td><%= @node.facts['bmc_ip_address'].human_empty %></td>"
        view << '   </tr>'
        view << '   <tr>'
        view << '     <td>BMC Firmware</td>'
        view << "     <td><%= @node.facts['bmc_firmware'].human_empty %></td>"
        view << '   </tr>'
        view << ' </tbody>'
        view << '</table>'
        view.join("\n")
      end
    end
  end
end
