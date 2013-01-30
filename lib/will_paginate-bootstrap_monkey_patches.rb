# Necessary patches to make pagination look correct in the version of
# Bootstrap used by Optopus.
class BootstrapPagination::Sinatra
  protected
  def page_number(page)
    if page == current_page
      tag('li', link(page, page), :class => 'active')
    else
      tag('li', link(page, page, :rel => rel_value(page)))
    end
  end

  def previous_or_next_page(page, text, classname)
    if page
      tag('li', link(text, page), :class => classname)
    else
      tag('li', link(text, '#'), :class => "%s disabled" % classname)
    end
  end
end
