class SeedProperties
  attr_reader :file, :created, :updated, :errors

  COLUMNS = {
    "name" => 0,
    "phone" => 1,
    "fax" => 2,
    "email" => 3,
    "contact_name" => 4,
    "units" => 5,
    "address" => 6,
    "city" => 7,
    "state" => 8,
    "zip" => 9,
    "listing_id" => 10,
    "website" => 11,
    "application" => 12
  }

  def initialize(filename=nil)
    @file = ( File.dirname(__FILE__) + '/properties_latest.csv' )
    raise "#{@file} not FOUND" unless File.exist?(@file)
    puts @file
    @lead_source = LeadSource.where(slug: 'Cloudmailin').first or
      raise "Could not find Lead Source 'Cloudmailin'"
  end

  def call(filename=nil)
    puts " * Loading Property Data from #{@file}"

    @created = []
    @updated = []
    @errors = []
    ActiveRecord::Base.transaction do
      puts " * Creating Properties"
      begin
      load_data.each do |row|
        name = row[COLUMNS["name"]]
        listing_id = row[COLUMNS["listing_id"]]

        property = Property.where(name: name).first || Property.new
        is_new = property.new_record?

        property.name = name
        property.phone = row[COLUMNS["phone"]]
        property.fax = row[COLUMNS["fax"]]
        property.email = row[COLUMNS["email"]]
        property.contact_name = row[COLUMNS["contact_name"]]
        property.units = row[COLUMNS["units"]]
        property.address1 = row[COLUMNS["address"]]
        property.city = row[COLUMNS["city"]]
        property.state = row[COLUMNS["state"]]
        property.zip = row[COLUMNS["zip"]]
        property.website = row[COLUMNS["website"]]
        property.application_url = row[COLUMNS["application"]]

        if property.save
          PropertyListing.create(
            property_id: property.id,
            source_id: @lead_source.id,
            code: listing_id,
            description: "Cloudmailin email +code",
            active: true)

            if is_new
              @created << "#{property.name}[#{property.id}]"
              puts "  -Created " + @created.last
            else
              @updated << "#{property.name}[#{property.id}]"
              puts "  - Updated " + @updated.last
            end
        else
          @errors << "#{property.name}: #{property.errors.to_a}"
          puts "  - Error " + @errors.last
        end
      end
      rescue => e
        puts e.to_s
        puts e.backtrace
        raise e
      end
      print_summary
    end
  end

  private

  def print_summary
  end

  def load_data
    CSV.read(@file, headers: true)
  end

end
