module UsersHelper
  def roles_for_select(user:, editor:, value:)
    roles = Role.all.to_a.
      select{|role| editor.role.present? ? editor.role >= role : false}.
      map{|role| [role.name, role.id]}
    options_for_select(roles, selected: value)
  end

  def teamroles_for_select(user:, editor:, value:)
    roles = Teamrole.all.to_a.
      #select{|role| editor.teamrole.present? ? editor.teamrole >= role : true}.
      map{|role| [role.name, role.id]}
    options_for_select(roles, selected: value)
  end
end
