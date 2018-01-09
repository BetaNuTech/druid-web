module UsersHelper
  def roles_for_select(user:, editor:, value:)
    # TODO Offer Roles based on Editor Role and access control
    roles = Role.all.to_a.
      select{|role| editor.role.present? ? editor.role >= role : false}.
      map{|role| [role.name, role.id]}
    options_for_select(roles, selected: value)

  end
end
