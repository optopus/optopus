module Optopus::AppHelpers::Menu
  # return menu sections relevant to current user only
  def menu_sections
    get_authorized_sections(Optopus::Menu.instance.sections)
  end

  def utility_menu_sections
    get_authorized_sections(Optopus::UtilityMenu.instance.sections)
  end

  def profile_menu_sections
    Optopus::ProfileMenu.instance.sections
  end

  def navlink_sections
    sections = Optopus.base_menus
    sections += settings.plugin_navigation
    get_authorized_sections(sections)
  end

  def get_authorized_sections(sections)
    sections.select do |section|
      if not section.required_role.nil?
        if section.required_role.kind_of?(String)
          if section.required_role.lines.any? { |r| is_authorized?(r) }
            section
          end
        else
          if section.required_role.any? { |r| is_authorized?(r) }
            section
          end
        end
      else
        section
      end
    end
  end
end
