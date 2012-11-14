module Optopus
  class App
    helpers do
      # return menu sections relevant to current user only
      def menu_sections
        Optopus::Menu.sections.select do |section|
          if section.required_role.any? { |r| is_authorized?(r) }
            section
          end
        end
      end

      def utility_menu_sections
        Optopus::UtilityMenu.sections.select do |section|
          if section.required_role.any? { |r| is_authorized?(r) }
            section
          end
        end
      end
    end
  end
end
