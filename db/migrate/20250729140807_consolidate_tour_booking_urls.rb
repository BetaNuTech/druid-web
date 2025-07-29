class ConsolidateTourBookingUrls < ActiveRecord::Migration[6.1]
  def change
    # Add new consolidated tour booking URL column
    add_column :properties, :tour_booking_url, :string
    
    # Migrate existing data (prefer virtual_tour_booking_url if both exist)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE properties 
          SET tour_booking_url = COALESCE(virtual_tour_booking_url, in_person_tour_booking_url)
          WHERE virtual_tour_booking_url IS NOT NULL OR in_person_tour_booking_url IS NOT NULL
        SQL
      end
    end
    
    # Remove old columns
    remove_column :properties, :virtual_tour_booking_url, :string
    remove_column :properties, :in_person_tour_booking_url, :string
  end
end
