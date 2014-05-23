module Optopus
  class App
    helpers do
      # return menu sections relevant to current user only
      def menu_sections
        Optopus::Menu.instance.sections.select do |section|
          if section.required_role.nil? || section.required_role.lines.any? { |r| is_authorized?(r) }
            section
          end
        end
      end

      def utility_menu_sections
        Optopus::UtilityMenu.instance.sections.select do |section|
          if section.required_role.nil? || section.required_role.lines.any? { |r| is_authorized?(r) }
            section
          end
        end
      end

      def profile_menu_sections
        Optopus::ProfileMenu.instance.sections
      end
    end
  end
end
