require 'csv'
require 'set'

namespace :prospects do
  desc 'Match CSV prospects against existing leads for a property'
  task :match, [:filename, :property_code] => :environment do |t, args|

    # Helper method to parse the prospect format (1, 2 or 3 rows per prospect)
    def parse_prospects_csv(filepath)
      all_prospects = []
      seen_emails = Set.new
      seen_phones = Set.new
      duplicate_emails = Hash.new(0)
      duplicate_phones = Hash.new(0)
      prospects_without_contact = []
      lines = File.readlines(filepath).map(&:strip).reject(&:empty?)

      i = 0
      while i < lines.length
        # Parse first row (name, date, channel, extra)
        row1 = CSV.parse_line(lines[i])

        # Skip if no valid data in row1
        if row1.nil? || row1[0].blank?
          i += 1
          next
        end

        name = row1[0]
        date = row1[1]
        channel = row1[2]
        extra = row1[3]

        email = nil
        phone = nil
        tags = nil
        touchpoint = nil
        rows_consumed = 1

        # Check if next row exists and is an email/phone row
        if lines[i + 1]
          row2 = CSV.parse_line(lines[i + 1])
          if row2 && row2[1].blank? && row2[0].present?
            # This is a contact row (email or phone)
            if row2[0].include?('@')
              # It's an email
              email = row2[0]
            elsif row2[0].gsub(/[^0-9]/, '').length >= 10
              # It's a phone number (has at least 10 digits)
              phone = row2[0]
            end
            tags = row2[2]
            touchpoint = row2[3]
            rows_consumed = 2

            # Check for a potential third row (phone if we have email, or email if we have phone)
            if lines[i + 2]
              row3 = CSV.parse_line(lines[i + 2])
              if row3 && row3[1].blank? && row3[0].present?
                if email.present? && row3[0].gsub(/[^0-9]/, '').length >= 10
                  # We have email already, this is a phone
                  phone = row3[0]
                  rows_consumed = 3
                elsif phone.present? && row3[0].include?('@')
                  # We have phone already, this is an email
                  email = row3[0]
                  rows_consumed = 3
                end
                # Update tags/touchpoint if present in row3
                tags = row3[2] if row3[2].present?
                touchpoint = row3[3] if row3[3].present?
              end
            end
          end
        end

        # Move the index forward by the number of rows consumed
        i += rows_consumed

        # Parse the name into first and last
        name_parts = name.to_s.strip.split(/\s+/)
        first_name = name_parts.first
        last_name = name_parts.size > 1 ? name_parts[1..-1].join(' ') : nil

        # Parse the date (format is M/D/YY)
        parsed_date = nil
        if date.present?
          begin
            # Handle format like "8/12/25" as August 12, 2025
            # Use strptime with explicit format to avoid Ruby's D/M/Y default interpretation
            if date =~ /(\d{1,2})\/(\d{1,2})\/(\d{2})$/
              month, day, year = $1, $2, $3
              # Add century to 2-digit year
              full_year = "20#{year}"
              # Use strptime with explicit M/D/Y format
              parsed_date = Date.strptime("#{month}/#{day}/#{full_year}", "%m/%d/%Y")
            else
              parsed_date = nil
            end
          rescue => e
            parsed_date = nil
          end
        end

        # Format phone number using the same logic as the Lead model
        formatted_phone = nil
        if phone.present?
          formatted_phone = PhoneNumber.format_phone(phone)
        end

        # Process prospect if we have contact info or valid name for matching
        if (email.present? && email.include?('@')) || formatted_phone.present? || (first_name.present? && last_name.present?)
          prospect = {
            name: name,
            first_name: first_name,
            last_name: last_name,
            email: email.present? && email.include?('@') ? email.downcase.strip : nil,
            phone: formatted_phone,
            date: date,
            parsed_date: parsed_date,
            channel: channel,
            extra: extra,
            tags: tags,
            touchpoint: touchpoint
          }

          # Track duplicates and add only unique contacts
          is_duplicate = false

          if prospect[:email].present?
            if seen_emails.include?(prospect[:email])
              duplicate_emails[prospect[:email]] += 1
              is_duplicate = true
            else
              seen_emails.add(prospect[:email])
            end
          end

          if prospect[:phone].present? && !is_duplicate
            if seen_phones.include?(prospect[:phone])
              duplicate_phones[prospect[:phone]] += 1
              is_duplicate = true
            else
              seen_phones.add(prospect[:phone])
            end
          end

          if !is_duplicate
            all_prospects << prospect
          elsif prospect[:email].blank? && prospect[:phone].blank?
            # Keep prospects without contact info (for name-based matching)
            prospects_without_contact << prospect
          end
        end
      end

      # Add prospects without contact info to the final list
      all_prospects.concat(prospects_without_contact)

      # Return prospects and stats
      {
        prospects: all_prospects,
        total_parsed: all_prospects.count + duplicate_emails.values.sum + duplicate_phones.values.sum,
        unique_with_email: seen_emails.size,
        unique_with_phone: seen_phones.size,
        without_contact: prospects_without_contact.count,
        duplicate_emails: duplicate_emails,
        duplicate_phones: duplicate_phones
      }
    end

    # Helper method to parse Yardi Prospect Directory Report format (standard CSV with headers)
    def parse_yardi_prospects_csv(filepath)
      all_prospects = []
      seen_emails = Set.new
      seen_phones = Set.new
      duplicate_emails = Hash.new(0)
      duplicate_phones = Hash.new(0)
      prospects_without_contact = []

      lines = File.readlines(filepath).map(&:strip).reject(&:empty?)

      # Find the header row (should be around row 5, contains "Property Name,Prospect Name...")
      header_row_index = nil
      lines.each_with_index do |line, idx|
        row = CSV.parse_line(line)
        if row && row[0] == 'Property Name' && row[1] == 'Prospect Name'
          header_row_index = idx
          break
        end
      end

      if header_row_index.nil?
        raise "Could not find header row in Yardi format CSV. Expected 'Property Name,Prospect Name,...'"
      end

      # Parse header to get column indices
      header = CSV.parse_line(lines[header_row_index])
      property_code_idx = header.index('Property Name')
      name_idx = header.index('Prospect Name')
      office_phone_idx = header.index('Office Tel. Number')
      cell_phone_idx = header.index('Cell Number')
      email_idx = header.index('Email')
      source_idx = header.index('Source')
      date_idx = header.index('Contact Date')
      agent_idx = header.index('Agent')
      status_idx = header.index('Status')

      # Process data rows (skip header and any metadata after it)
      data_start = header_row_index + 1

      # Skip the property name repeat row if it exists
      if data_start < lines.length
        first_data_row = CSV.parse_line(lines[data_start])
        # Check if this is a property name row (has property name but no prospect name)
        if first_data_row && first_data_row[name_idx].blank? && first_data_row[property_code_idx].present?
          data_start += 1
        end
      end

      lines[data_start..-1].each do |line|
        row = CSV.parse_line(line)
        next unless row && row.size > name_idx

        name = row[name_idx]
        next if name.blank?

        # Skip property name separator rows
        next if row[email_idx].blank? && row[cell_phone_idx].blank? && row[office_phone_idx].blank?

        email = row[email_idx]
        cell_phone = row[cell_phone_idx]
        office_phone = row[office_phone_idx]
        source = row[source_idx]
        date = row[date_idx]
        agent = row[agent_idx]
        status = row[status_idx]

        # Filter out Yardi scrubbed emails
        email = nil if email.present? && email.include?('@yardi.scrub')

        # Prefer cell phone over office phone
        phone = cell_phone.present? ? cell_phone : office_phone

        # Format and validate phone number
        formatted_phone = nil
        if phone.present?
          # Skip obviously invalid phone numbers
          cleaned = phone.gsub(/[^0-9]/, '')
          if cleaned.length >= 10 && !phone.include?('(000)000-0000')
            formatted_phone = PhoneNumber.format_phone(phone)
          end
        end

        # Parse name into first and last
        name_parts = name.to_s.strip.split(/\s+/)
        first_name = name_parts.first
        last_name = name_parts.size > 1 ? name_parts[1..-1].join(' ') : nil

        # Parse the date (format is M/D/YYYY)
        parsed_date = nil
        if date.present?
          begin
            # Handle format like "6/10/2025"
            parsed_date = Date.strptime(date, "%m/%d/%Y")
          rescue => e
            # Try alternate parsing
            begin
              parts = date.split('/')
              if parts.length == 3
                month, day, year = parts
                parsed_date = Date.new(year.to_i, month.to_i, day.to_i)
              end
            rescue
              parsed_date = nil
            end
          end
        end

        # Clean email
        clean_email = email.present? && email.include?('@') ? email.downcase.strip : nil

        # Process prospect if we have contact info or valid name for matching
        if clean_email.present? || formatted_phone.present? || (first_name.present? && last_name.present?)
          prospect = {
            name: name,
            first_name: first_name,
            last_name: last_name,
            email: clean_email,
            phone: formatted_phone,
            date: date,
            parsed_date: parsed_date,
            channel: source,
            agent: agent,
            status: status,
            extra: nil,
            tags: nil,
            touchpoint: nil
          }

          # Track duplicates and add only unique contacts
          is_duplicate = false

          if prospect[:email].present?
            if seen_emails.include?(prospect[:email])
              duplicate_emails[prospect[:email]] += 1
              is_duplicate = true
            else
              seen_emails.add(prospect[:email])
            end
          end

          if prospect[:phone].present? && !is_duplicate
            if seen_phones.include?(prospect[:phone])
              duplicate_phones[prospect[:phone]] += 1
              is_duplicate = true
            else
              seen_phones.add(prospect[:phone])
            end
          end

          if !is_duplicate
            all_prospects << prospect
          elsif prospect[:email].blank? && prospect[:phone].blank?
            # Keep prospects without contact info (for name-based matching)
            prospects_without_contact << prospect
          end
        end
      end

      # Add prospects without contact info to the final list
      all_prospects.concat(prospects_without_contact)

      # Return prospects and stats
      {
        prospects: all_prospects,
        total_parsed: all_prospects.count + duplicate_emails.values.sum + duplicate_phones.values.sum,
        unique_with_email: seen_emails.size,
        unique_with_phone: seen_phones.size,
        without_contact: prospects_without_contact.count,
        duplicate_emails: duplicate_emails,
        duplicate_phones: duplicate_phones
      }
    end

    # Helper to detect CSV format
    def detect_csv_format(filepath)
      # Read first 10 lines to check format
      lines = File.readlines(filepath).first(10)

      lines.each do |line|
        row = CSV.parse_line(line)
        if row && row[0] == 'Property Name' && row[1] == 'Prospect Name'
          return :yardi
        end
      end

      :legacy
    end

    # Determine filename and property code
    filename = args[:filename]
    property_code = args[:property_code]

    # If no filename provided, prompt for it
    if filename.blank?
      puts "Enter the CSV filename (or full path):"
      filename = STDIN.gets.chomp
    end

    # Try to extract property code from filename if not provided
    if property_code.blank? && filename.present?
      # Extract from patterns like "prospects_1002edge.csv"
      if filename =~ /prospects[_\-]?(\d+\w+)/i
        property_code = $1
      else
        puts "Enter the property code (e.g., 1002edge):"
        property_code = STDIN.gets.chomp
      end
    end

    # Find the CSV file
    filepath = if File.exist?(filename)
      filename
    elsif File.exist?(Rails.root.join('tmp', 'prospects', filename))
      Rails.root.join('tmp', 'prospects', filename)
    else
      puts "Error: File not found: #{filename}"
      puts "Looked in current directory and tmp/prospects/"
      exit
    end

    # Find the property by PropertyListing code
    property = nil

    # First try to find by PropertyListing code
    listing = PropertyListing.active.where("LOWER(code) = ?", property_code.downcase).first
    property = listing.property if listing

    # If not found, try property name match as fallback
    if property.nil?
      property = Property.where("LOWER(name) LIKE ?", "%#{property_code.downcase}%").first
    end

    # Try removing numbers for codes like "1002edge" -> "edge"
    if property.nil? && property_code =~ /^\d+(.+)$/
      code_without_numbers = $1
      listing = PropertyListing.active.where("LOWER(code) LIKE ?", "%#{code_without_numbers.downcase}%").first
      property = listing.property if listing
      property ||= Property.where("LOWER(name) LIKE ?", "%#{code_without_numbers.downcase}%").first
    end

    if property.nil?
      puts "Error: Could not find property with code: #{property_code}"
      puts "\nAvailable property codes:"
      PropertyListing.active.includes(:property).order("properties.name").each do |listing|
        puts "  - #{listing.code.ljust(15)} => #{listing.property.name}"
      end
      exit
    end

    puts "Processing prospects for property: #{property.name}"
    puts "Reading file: #{filepath}"

    # Detect CSV format
    csv_format = detect_csv_format(filepath)
    puts "Detected format: #{csv_format == :yardi ? 'Yardi Prospect Directory Report' : 'Legacy multi-row format'}"
    puts "-" * 50

    # Parse the CSV using the appropriate parser
    result = if csv_format == :yardi
      parse_yardi_prospects_csv(filepath)
    else
      parse_prospects_csv(filepath)
    end
    prospects = result[:prospects]

    # Print input file statistics
    puts "Input File Statistics:"
    puts "  Total records in file: #{result[:total_parsed]}"
    puts "  Unique prospects after deduplication: #{prospects.count}"
    puts "    - With email: #{result[:unique_with_email]}"
    puts "    - With phone: #{result[:unique_with_phone]}"
    puts "    - Without email or phone: #{result[:without_contact]}"

    if result[:duplicate_emails].any?
      puts "  Duplicate emails removed: #{result[:duplicate_emails].values.sum} total"
      # Show top 5 most duplicated emails
      top_duplicates = result[:duplicate_emails].sort_by { |_, count| -count }.first(5)
      puts "    Top email duplicates:"
      top_duplicates.each do |email, count|
        puts "      - #{email}: #{count + 1} occurrences (kept 1, removed #{count})"
      end
    else
      puts "  No duplicate emails found"
    end

    if result[:duplicate_phones].any?
      puts "  Duplicate phones removed: #{result[:duplicate_phones].values.sum} total"
      # Show top 5 most duplicated phones
      top_duplicates = result[:duplicate_phones].sort_by { |_, count| -count }.first(5)
      puts "    Top phone duplicates:"
      top_duplicates.each do |phone, count|
        puts "      - #{phone}: #{count + 1} occurrences (kept 1, removed #{count})"
      end
    else
      puts "  No duplicate phones found"
    end

    # Calculate monthly breakdown of unique prospects
    puts "\nUnique Prospects by Month:"
    monthly_counts = Hash.new(0)
    no_date_count = 0

    prospects.each do |prospect|
      if prospect[:parsed_date]
        month_key = prospect[:parsed_date].strftime('%B %Y')
        monthly_counts[month_key] += 1
      else
        no_date_count += 1
      end
    end

    # Sort by date and display
    if monthly_counts.any?
      monthly_counts.sort_by { |month_str, _|
        Date.strptime(month_str, '%B %Y')
      }.each do |month, count|
        puts "  #{month}: #{count}"
      end
    end

    puts "  No date provided: #{no_date_count}" if no_date_count > 0

    puts "-" * 50
    puts "Processing #{prospects.count} unique prospects..."

    # Process prospects and match against leads
    matched = []
    matched_prospects = [] # Track which prospects found matches
    unmatched = []

    prospects.each_with_index do |prospect, index|
      print "\rProcessing: #{index + 1}/#{prospects.count}"

      leads_found = []
      match_type = nil

      # First try to match by email if available
      if prospect[:email].present?
        leads_found = Lead.where(property_id: property.id, email: prospect[:email]).to_a
        match_type = 'email' if leads_found.any?
      end

      # If no email match, try phone matching
      if leads_found.empty? && prospect[:phone].present?
        # Check both phone1 and phone2 fields
        leads_found = Lead.where(property_id: property.id).where(
          "phone1 = :phone OR phone2 = :phone", phone: prospect[:phone]
        ).to_a
        match_type = 'phone' if leads_found.any?
      end

      # If no email or phone match, try name matching with date proximity
      if leads_found.empty? && prospect[:first_name].present? && prospect[:last_name].present?
        name_leads = nil

        # Check if first name or last name is just an initial (single letter, possibly with period)
        first_is_initial = prospect[:first_name].gsub('.', '').length == 1
        last_is_initial = prospect[:last_name].gsub('.', '').length == 1

        if first_is_initial && !last_is_initial
          # Match by first initial and full last name
          first_initial = prospect[:first_name].gsub('.', '').upcase[0]
          name_leads = Lead.where(
            property_id: property.id,
            last_name: prospect[:last_name]
          ).where("UPPER(LEFT(first_name, 1)) = ?", first_initial)
          match_type = 'initial+last' if name_leads.any?
        elsif !first_is_initial && last_is_initial
          # Match by full first name and last initial
          last_initial = prospect[:last_name].gsub('.', '').upcase[0]
          name_leads = Lead.where(
            property_id: property.id,
            first_name: prospect[:first_name]
          ).where("UPPER(LEFT(last_name, 1)) = ?", last_initial)
          match_type = 'first+initial' if name_leads.any?
        elsif first_is_initial && last_is_initial
          # Both are initials - match by both initials
          first_initial = prospect[:first_name].gsub('.', '').upcase[0]
          last_initial = prospect[:last_name].gsub('.', '').upcase[0]
          name_leads = Lead.where(
            property_id: property.id
          ).where("UPPER(LEFT(first_name, 1)) = ? AND UPPER(LEFT(last_name, 1)) = ?", first_initial, last_initial)
          match_type = 'initials' if name_leads.any?
        else
          # Both are full names - exact match
          name_leads = Lead.where(
            property_id: property.id,
            first_name: prospect[:first_name],
            last_name: prospect[:last_name]
          )
          match_type = 'name' if name_leads.any?
        end

        # Filter by date proximity (within 1 month of prospect date)
        if prospect[:parsed_date] && name_leads && name_leads.any?
          date_range = (prospect[:parsed_date] - 30.days)..(prospect[:parsed_date] + 30.days)
          name_leads = name_leads.where(created_at: date_range)

          if name_leads.any?
            leads_found = name_leads.to_a
            # match_type is already set above based on the type of match
          else
            match_type = nil  # Reset if date filtering removed all matches
          end
        end
      end

      if leads_found.any?
        # Track this prospect as matched (only once per prospect)
        matched_prospects << prospect

        # Get state info for each matching lead
        leads_found.each do |lead|
          # Get most recent transition
          last_transition = lead.transitions.order(created_at: :desc).first

          matched << {
            name: prospect[:name],
            email: prospect[:email] || lead.email,
            phone: prospect[:phone] || lead.phone1 || lead.phone2,
            lead_id: lead.id,
            current_state: lead.state || 'unknown',
            state_changed_at: last_transition&.created_at || lead.updated_at,
            duplicate_count: leads_found.count,
            match_type: match_type
          }
        end
      else
        unmatched << prospect
      end
    end

    puts "\n" + "-" * 50
    puts "Results:"
    email_matches = matched.select { |m| m[:match_type] == 'email' }.count
    phone_matches = matched.select { |m| m[:match_type] == 'phone' }.count
    name_matches = matched.select { |m| m[:match_type] == 'name' }.count
    initial_last_matches = matched.select { |m| m[:match_type] == 'initial+last' }.count
    first_initial_matches = matched.select { |m| m[:match_type] == 'first+initial' }.count
    initials_matches = matched.select { |m| m[:match_type] == 'initials' }.count

    # Show how many database leads were matched and how many unique prospects had matches
    puts "  Matched prospects: #{matched_prospects.count} out of #{prospects.count}"
    puts "  Total lead matches: #{matched.count} (some prospects matched multiple leads)"
    puts "  Match types breakdown:"
    puts "    - By email: #{email_matches}"
    puts "    - By phone: #{phone_matches}"
    puts "    - By full name: #{name_matches}"
    puts "    - By initial+last: #{initial_last_matches}" if initial_last_matches > 0
    puts "    - By first+initial: #{first_initial_matches}" if first_initial_matches > 0
    puts "    - By initials only: #{initials_matches}" if initials_matches > 0
    puts "  Unmatched prospects: #{unmatched.count}"

    # Create output directory if it doesn't exist
    output_dir = Rails.root.join('tmp', 'prospects', 'results')
    FileUtils.mkdir_p(output_dir)

    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')

    # Write matched prospects CSV
    if matched.any?
      matched_file = output_dir.join("#{property_code}_matched_#{timestamp}.csv")
      CSV.open(matched_file, 'w') do |csv|
        csv << ['Name', 'Email', 'Phone', 'Current State', 'State Changed Date', 'Lead ID', 'Match Type', 'Duplicate Count']
        matched.each do |m|
          csv << [
            m[:name],
            m[:email],
            m[:phone],
            m[:current_state],
            m[:state_changed_at]&.strftime('%Y-%m-%d %H:%M'),
            m[:lead_id],
            m[:match_type],
            m[:duplicate_count] > 1 ? m[:duplicate_count] : nil
          ]
        end
      end
      puts "\nMatched prospects written to: #{matched_file}"
    end

    # Write unmatched prospects CSV
    if unmatched.any?
      unmatched_file = output_dir.join("#{property_code}_unmatched_#{timestamp}.csv")
      CSV.open(unmatched_file, 'w') do |csv|
        csv << ['Name', 'Email', 'Phone', 'Date', 'Channel', 'Tags/Touches']
        unmatched.each do |u|
          csv << [
            u[:name],
            u[:email],
            u[:phone],
            u[:date],
            u[:channel],
            [u[:tags], u[:touchpoint]].compact.join(' / ')
          ]
        end
      end
      puts "Unmatched prospects written to: #{unmatched_file}"
    end

    puts "\nDone!"
  end

  desc 'Create leads from unmatched prospects CSV file'
  task :create_leads, [:filename, :property_code, :dry_run] => :environment do |t, args|
    filename = args[:filename]
    property_code = args[:property_code]
    dry_run = args[:dry_run] == 'true'

    # If no filename, try to read from stdin (works locally, not on Heroku)
    if filename.blank? || filename == '-'
      puts "Reading CSV from stdin (Note: This only works locally, not on Heroku)..."
      csv_content = STDIN.read
      if csv_content.blank?
        puts "Error: No CSV data provided via stdin"
        puts "For local use: cat unmatched.csv | bundle exec rake 'prospects:create_leads[-,property_code]'"
        puts "For Heroku: Upload CSV to S3/Gist first, then download within Heroku bash session"
        exit 1
      end
      csv_lines = csv_content.split("\n")
    else
      # Read from file
      filepath = if File.exist?(filename)
        filename
      elsif File.exist?(Rails.root.join('tmp', 'prospects', 'results', filename))
        Rails.root.join('tmp', 'prospects', 'results', filename)
      elsif File.exist?(Rails.root.join('tmp', 'prospects', filename))
        Rails.root.join('tmp', 'prospects', filename)
      else
        puts "Error: File not found: #{filename}"
        puts "Looked in current directory, tmp/prospects/, and tmp/prospects/results/"
        exit 1
      end

      puts "Reading file: #{filepath}"
      csv_lines = File.readlines(filepath)
    end

    # Parse property code
    if property_code.blank?
      puts "Error: Property code is required"
      puts "Usage: bundle exec rake 'prospects:create_leads[filename.csv,property_code]'"
      exit 1
    end

    # Find the property
    property = nil
    listing = PropertyListing.active.where("LOWER(code) = ?", property_code.downcase).first
    property = listing.property if listing

    if property.nil?
      property = Property.where("LOWER(name) LIKE ?", "%#{property_code.downcase}%").first
    end

    if property.nil? && property_code =~ /^\d+(.+)$/
      code_without_numbers = $1
      listing = PropertyListing.active.where("LOWER(code) LIKE ?", "%#{code_without_numbers.downcase}%").first
      property = listing.property if listing
      property ||= Property.where("LOWER(name) LIKE ?", "%#{code_without_numbers.downcase}%").first
    end

    if property.nil?
      puts "Error: Could not find property with code: #{property_code}"
      puts "\nAvailable property codes:"
      PropertyListing.active.includes(:property).order("properties.name").limit(10).each do |listing|
        puts "  - #{listing.code.ljust(15)} => #{listing.property.name}"
      end
      exit 1
    end

    # Get or create a manual/CSV import lead source
    source = LeadSource.find_or_create_by(slug: 'manual-csv-import') do |s|
      s.name = 'Manual CSV Import'
      s.active = true
      s.incoming = true
      s.api_token = SecureRandom.hex(16)
    end

    puts "\n" + "="*60
    puts dry_run ? "DRY RUN MODE - No leads will be created" : "CREATING LEADS"
    puts "Property: #{property.name}"
    puts "Lead Source: #{source.name}"
    puts "="*60

    # Parse CSV
    created_leads = []
    skipped_rows = []
    error_rows = []

    # Parse header row
    header = CSV.parse_line(csv_lines.first)
    unless header && header.include?('Name')
      puts "Error: CSV must have a header row with at least 'Name' column"
      puts "Expected columns: Name, Email, Phone, Date, Channel, Tags/Touches"
      exit 1
    end

    # Get column indices
    name_idx = header.index('Name')
    email_idx = header.index('Email')
    phone_idx = header.index('Phone')
    date_idx = header.index('Date')
    channel_idx = header.index('Channel')

    # Process each row
    csv_lines[1..-1].each_with_index do |line, index|
      row_num = index + 2
      next if line.strip.empty?

      row = CSV.parse_line(line)
      next unless row

      name = row[name_idx]
      email = row[email_idx]
      phone = row[phone_idx]
      date = row[date_idx]
      channel = row[channel_idx]

      # Skip if no email or phone
      if (email.nil? || email.strip.empty?) && (phone.nil? || phone.strip.empty?)
        skipped_rows << {row: row_num, reason: "No email or phone", name: name}
        next
      end

      # Parse name
      if name.present? && name != 'Unknown'
        name_parts = name.strip.split(/\s+/)
        first_name = name_parts.first || 'Unknown'
        last_name = name_parts.size > 1 ? name_parts[1..-1].join(' ') : 'Unknown'
      else
        first_name = 'Unknown'
        last_name = 'Prospect'
      end

      # Format phone (remove formatting, keep as 10 digits)
      if phone.present?
        phone = PhoneNumber.format_phone(phone)
      end

      # Check for existing lead with same email or phone at this property
      existing_lead = nil
      if email.present?
        existing_lead = Lead.where(property_id: property.id, email: email.downcase).first
      end

      if existing_lead.nil? && phone.present?
        existing_lead = Lead.where(property_id: property.id)
                            .where("phone1 = ? OR phone2 = ?", phone, phone).first
      end

      if existing_lead
        skipped_rows << {
          row: row_num,
          reason: "Duplicate (Lead ##{existing_lead.id})",
          name: name,
          email: email,
          phone: phone
        }
        next
      end

      # Parse date for first_comm
      first_comm = nil
      if date.present?
        begin
          # Handle various date formats (M/D/YY or MM/DD/YYYY)
          # Assume 2-digit years are 2025
          date_str = date.strip
          parsed_date = Date.strptime(date_str, '%m/%d/%y') rescue Date.strptime(date_str, '%m/%d/%Y')
          # If year is < 100, assume it's 2000s
          if parsed_date.year < 100
            parsed_date = Date.new(2000 + parsed_date.year, parsed_date.month, parsed_date.day)
          end
          first_comm = parsed_date.to_datetime
        rescue StandardError => e
          puts "Warning: Could not parse date '#{date}' for row #{row_num}: #{e.message}"
        end
      end

      # Build notes with original date if available
      notes = []
      notes << "Imported from CSV: #{channel}" if channel.present?
      notes << "Original date: #{date}" if date.present? && first_comm.nil?
      notes_text = notes.any? ? notes.join(', ') : nil

      # Create lead (or simulate in dry run)
      if dry_run
        puts "Would create: #{first_name} #{last_name} | #{email || 'no email'} | #{phone || 'no phone'} | first_comm: #{first_comm || 'not set'}"
        created_leads << {
          name: "#{first_name} #{last_name}",
          email: email,
          phone: phone,
          first_comm: first_comm,
          row: row_num
        }
      else
        begin
          lead = Lead.create!(
            property_id: property.id,
            lead_source_id: source.id,
            first_name: first_name,
            last_name: last_name,
            email: email.present? ? email.downcase : nil,
            phone1: phone,
            referral: channel || 'CSV Import',
            state: 'open',
            priority: 'high',
            notes: notes_text,
            first_comm: first_comm
          )

          # Create preference for the lead (required by views)
          lead.build_preference
          lead.save!

          created_leads << {
            id: lead.id,
            name: "#{first_name} #{last_name}",
            email: email,
            phone: phone,
            first_comm: first_comm,
            row: row_num
          }

          print "."
        rescue => e
          error_rows << {
            row: row_num,
            name: name,
            error: e.message
          }
          print "x"
        end
      end
    end

    # Summary report
    puts "\n\n" + "="*60
    puts "IMPORT SUMMARY"
    puts "="*60
    puts "Total rows processed: #{csv_lines.size - 1}"
    puts "Leads created: #{created_leads.size}"
    puts "Rows skipped: #{skipped_rows.size}"
    puts "Errors: #{error_rows.size}"

    if skipped_rows.any?
      puts "\nSkipped Rows:"
      skipped_rows.first(10).each do |skip|
        puts "  Row #{skip[:row]}: #{skip[:name]} - #{skip[:reason]}"
      end
      puts "  ... and #{skipped_rows.size - 10} more" if skipped_rows.size > 10
    end

    if error_rows.any?
      puts "\nError Rows:"
      error_rows.each do |error|
        puts "  Row #{error[:row]}: #{error[:name]} - #{error[:error]}"
      end
    end

    if created_leads.any? && !dry_run
      puts "\nCreated Leads:"
      created_leads.first(5).each do |lead|
        puts "  Lead ##{lead[:id]}: #{lead[:name]} (#{lead[:email] || lead[:phone]})"
      end
      puts "  ... and #{created_leads.size - 5} more" if created_leads.size > 5

      # Write results to file
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      output_file = Rails.root.join('tmp', 'prospects', 'results', "created_leads_#{property_code}_#{timestamp}.csv")
      FileUtils.mkdir_p(File.dirname(output_file))

      CSV.open(output_file, 'w') do |csv|
        csv << ['Lead ID', 'Name', 'Email', 'Phone', 'First Contact', 'Source Row']
        created_leads.each do |lead|
          csv << [lead[:id], lead[:name], lead[:email], lead[:phone], lead[:first_comm], lead[:row]]
        end
      end

      puts "\nResults saved to: #{output_file}"
    end

    puts "\nDone!"
  end
end