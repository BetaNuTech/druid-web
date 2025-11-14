module Leads
  class NameParser
    # Parse and fix lead names that are malformed
    # Common issues:
    # 1. "LAST,FIRST" format (e.g., "BARNES,AURORA")
    # 2. Both names in first_name field (e.g., "John Smith")
    # 3. Missing last_name
    #
    # Returns: { first_name: String, last_name: String, changed: Boolean }
    def self.parse_and_fix(lead)
      first_name = lead.first_name.to_s.strip
      last_name = lead.last_name.to_s.strip

      # Already valid - has both first and last name
      if first_name.present? && last_name.present? && !first_name.include?(',')
        return { first_name: first_name, last_name: last_name, changed: false }
      end

      # Case 1: "LAST,FIRST" format in first_name
      if first_name.include?(',')
        parts = first_name.split(',', 2).map(&:strip)
        return {
          first_name: parts[1].presence || parts[0], # Second part is first name
          last_name: parts[0],                        # First part is last name
          changed: true,
          reason: "Comma-separated format detected (LAST,FIRST)"
        }
      end

      # Case 2: Both names in first_name field, last_name missing or whitespace
      if first_name.present? && (last_name.blank? || last_name == ' ')
        # Split on whitespace
        name_parts = first_name.split(/\s+/)

        if name_parts.size >= 2
          # Take first part as first name, rest as last name
          return {
            first_name: name_parts.first,
            last_name: name_parts[1..-1].join(' '),
            changed: true,
            reason: "Multiple names in first_name field"
          }
        elsif name_parts.size == 1
          # Only one name - use it as first name, set placeholder last name
          return {
            first_name: name_parts.first,
            last_name: name_parts.first, # Use same name for both (Yardi requirement)
            changed: true,
            reason: "Single name only - duplicated to last_name"
          }
        end
      end

      # Case 3: Missing last_name entirely
      if first_name.present? && last_name.blank?
        return {
          first_name: first_name,
          last_name: first_name, # Use first name for both (Yardi requirement)
          changed: true,
          reason: "Missing last_name - duplicated from first_name"
        }
      end

      # Case 4: Missing first_name
      if last_name.present? && first_name.blank?
        return {
          first_name: last_name, # Use last name for both
          last_name: last_name,
          changed: true,
          reason: "Missing first_name - duplicated from last_name"
        }
      end

      # Case 5: Both missing - return Unknown
      if first_name.blank? && last_name.blank?
        return {
          first_name: "Unknown",
          last_name: "Unknown",
          changed: true,
          reason: "Both names missing - set to Unknown"
        }
      end

      # Fallback - no change needed
      return { first_name: first_name, last_name: last_name, changed: false }
    end

    # Fix the lead's name in place and save (only updates name fields)
    # Returns: { success: Boolean, changed: Boolean, reason: String, errors: Array }
    def self.fix_and_save!(lead)
      result = parse_and_fix(lead)

      if !result[:changed]
        return {
          success: true,
          changed: false,
          reason: "Name already valid",
          errors: []
        }
      end

      # Update only the name fields
      lead.first_name = result[:first_name]
      lead.last_name = result[:last_name]

      # Save with validation but only for name fields
      # Use update_columns to bypass callbacks and validations if needed
      # Or use save to respect validations
      if lead.save
        return {
          success: true,
          changed: true,
          reason: result[:reason],
          old_first_name: lead.first_name_was,
          old_last_name: lead.last_name_was,
          new_first_name: result[:first_name],
          new_last_name: result[:last_name],
          errors: []
        }
      else
        return {
          success: false,
          changed: false,
          reason: result[:reason],
          errors: lead.errors.full_messages
        }
      end
    end

    # Bulk fix names for a collection of leads
    # Returns: { fixed: Integer, failed: Integer, unchanged: Integer, results: Array }
    def self.bulk_fix!(leads)
      results = {
        fixed: 0,
        failed: 0,
        unchanged: 0,
        details: []
      }

      leads.each do |lead|
        fix_result = fix_and_save!(lead)

        if fix_result[:success] && fix_result[:changed]
          results[:fixed] += 1
        elsif !fix_result[:success]
          results[:failed] += 1
        else
          results[:unchanged] += 1
        end

        results[:details] << {
          lead_id: lead.id,
          name: lead.name,
          result: fix_result
        }
      end

      results
    end
  end
end
