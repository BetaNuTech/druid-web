class RemoveOakleighProperty < ActiveRecord::Migration[5.2]
  def change
    Property.where(name: 'Oakleigh').first&.destroy
  end
end
