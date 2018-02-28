module ReasonsHelper
  def select_reason(val)
    options_for_select(Reason.order(name: 'ASC').map{|r| [r.name, r.id]}, val)
  end
end
