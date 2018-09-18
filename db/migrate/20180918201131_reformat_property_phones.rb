class ReformatPropertyPhones < ActiveRecord::Migration[5.2]
  def change
    Property.all.map{|p| p.touch; p.save}
    Lead.all.map{|l| l.touch; l.save}
  end
end
