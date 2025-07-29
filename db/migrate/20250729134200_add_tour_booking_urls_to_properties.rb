class AddTourBookingUrlsToProperties < ActiveRecord::Migration[6.1]
  def change
    add_column :properties, :virtual_tour_booking_url, :string
    add_column :properties, :in_person_tour_booking_url, :string
  end
end
