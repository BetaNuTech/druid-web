module UsersHelper
  def roles_for_select(user:, editor:, value:)
    roles = Users::Policy.new(editor, user).roles_for_select
    options_for_select(roles, selected: value)
  end

  def teamroles_for_select(user:, editor:, value:)
    roles = Users::Policy.new(editor, user).teamroles_for_select
    options_for_select(roles, selected: value)
  end

  def user_creator_form_group(attr)
    if defined?(@creator) && @creator.error_for?(attr)
      content_tag(:div, class: 'field_with_errors') do
        yield
      end
    else
      yield
    end
  end
end
