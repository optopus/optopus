module Optopus
  class App
    helpers do
      # return menu sections relevant to current user only
      def menu_sections
        Optopus::Menu.sections.select do |section|
          section if is_authorized?(section.required_role)
        end
      end

      def utility_menu_sections
        Optopus::UtilityMenu.sections.select do |section|
          section if is_authorized?(section.required_role)
        end
      end
    end
  end
end
