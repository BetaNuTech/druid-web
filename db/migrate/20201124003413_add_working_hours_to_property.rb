class AddWorkingHoursToProperty < ActiveRecord::Migration[6.0]
  def change
    add_column :properties, :working_hours, :jsonb
    Property.update_all(
      working_hours: 
      {
        "monday" => {
          "morning" => {
            "open" => "7:00 AM",
            "close" => "12:00 PM"
          },
          "afternoon" => {
            "open" => "12:00 PM",
            "close" => "6:00 PM"
          }
        },
        "tuesday" => {
          "morning" => {
            "open" => "7:00 AM",
            "close" => "12:00 PM"
          },
          "afternoon" => {
            "open" => "12:00 PM",
            "close" => "6:00 PM"
          }
        },
        "wednesday" => {
          "morning" => {
            "open" => "7:00 AM",
            "close" => "12:00 PM"
          },
          "afternoon" => {
            "open" => "12:00 PM",
            "close" => "6:00 PM"
          }
        },
        "thursday" => {
          "morning" => {
            "open" => "7:00 AM",
            "close" => "12:00 PM"
          },
          "afternoon" => {
            "open" => "12:00 PM",
            "close" => "6:00 PM"
          }
        },
        "friday" => {
          "morning" => {
            "open" => "7:00 AM",
            "close" => "12:00 PM"
          },
          "afternoon" => {
            "open" => "12:00 PM",
            "close" => "6:00 PM"
          }
        },
        "saturday" => {
          "morning" => {
            "open" => "7:00 AM",
            "close" => "12:00 PM"
          },
          "afternoon" => {
            "open" => "12:00 PM",
            "close" => "6:00 PM"
          }
        },
        "sunday" => {
          "morning" => {
            "open" => "7:00 AM",
            "close" => "12:00 PM"
          },
          "afternoon" => {
            "open" => "12:00 PM",
            "close" => "6:00 PM"
          }
        }
      })
  end
end
