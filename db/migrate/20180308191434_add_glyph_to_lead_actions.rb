class AddGlyphToLeadActions < ActiveRecord::Migration[5.1]
  def change
    add_column :lead_actions, :glyph, :string
  end
end
