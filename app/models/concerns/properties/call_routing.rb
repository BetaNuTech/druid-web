module Properties
  # Readiness of a Property for incoming call handling and phone lead
  # attribution.
  #
  # Every incoming call hits Property.property_info_for_incoming_number
  # (api/v1/leads#property_info). The call center uses that response to
  # forward the call and, when the caller becomes a lead, posts it back with
  # the property code and marketing source name from the same response. A
  # property missing a :blocking setting below either cannot route the call
  # or produces a lead that cannot be attributed - silently, in both cases.
  #
  # Blank leasing/maintenance numbers are deliberately NOT flagged: they fall
  # back to the main line by design (see property_info_for_incoming_number),
  # which is exactly why the main line itself is blocking.
  #
  # See doc/property_call_routing.md.
  module CallRouting
    extend ActiveSupport::Concern

    CALL_CENTER_SOURCE_SLUG = 'CallCenter'.freeze
    VOYAGER_SOURCE_SLUG = 'YardiVoyager'.freeze

    # Ordered most to least severe. :check names a predicate on Property.
    CHECKS = [
      {
        key: :main_line,
        severity: :blocking,
        check: :main_line_missing?,
        message: 'The main line phone number is not set. Incoming calls cannot be ' \
                 'resolved to this property, and calls to a marketing tracking number ' \
                 'have no destination to forward to.'
      },
      {
        key: :call_center_listing,
        severity: :blocking,
        check: :call_center_listing_missing?,
        message: 'There is no active CallCenter property listing code. Phone leads come ' \
                 'back tagged with that code, and without it the lead is created with no ' \
                 'property at all - no agent assignment and no engagement policy.'
      },
      {
        key: :timezone,
        severity: :warning,
        check: :timezone_unset?,
        message: 'The timezone is still the UTC default. The open/closed flag and hours ' \
                 'reported to the call center will be several hours off.'
      },
      {
        key: :voyager_listing,
        severity: :warning,
        check: :voyager_listing_missing?,
        message: 'There is no active YardiVoyager property listing code. Guest cards ' \
                 'cannot be pushed to Voyager and the marketing source name audit is ' \
                 'skipped for this property.'
      },
      {
        key: :office_hours,
        severity: :warning,
        check: :office_hours_missing?,
        message: 'Office hours have not been set. This does not stop a call from being ' \
                 'forwarded or attributed - it only makes the open/closed flag and ' \
                 'hours reported to the call center fall back to defaults.'
      }
    ].freeze

    included do
      # The main line is what an incoming call to the property itself is
      # resolved by, and it is the fallback destination whenever the leasing
      # or maintenance number is blank - so a blank main line blanks all
      # three numbers in the routing payload at once.
      def main_line_missing?
        phone.blank?
      end

      def marketing_tracking_numbers?
        marketing_sources.where.not(tracking_number: [nil, '']).exists?
      end

      # True when marketing tracking numbers are in use but the main line
      # they depend on has not been set.
      def marketing_tracking_numbers_without_main_line?
        main_line_missing? && marketing_tracking_numbers?
      end

      # The property code returned to the call center, and the code it posts
      # back when creating a phone lead. Leads::Creator resolves it with
      # Property.find_by_code_and_source, which requires both the listing and
      # the lead source to be active - so an inactive listing is as bad as a
      # missing one.
      def call_center_listing_code
        PropertyListing.includes(:source).
          active.
          where(property_id: id, lead_sources: {slug: CALL_CENTER_SOURCE_SLUG, active: true}).
          first&.code
      end

      def call_center_listing_missing?
        call_center_listing_code.blank?
      end

      def voyager_listing_missing?
        voyager_property_code.blank?
      end

      # The timezone drives office_open? and the hours reported to the call
      # center. It defaults to UTC and is never blank, so a property left at
      # the default is wrong without ever raising.
      def timezone_unset?
        timezone.blank? || timezone == 'UTC'
      end

      # Everything standing between this property and a correctly routed,
      # correctly attributed phone lead, most severe first. Returns an Array
      # of Hashes with :key, :severity (:blocking or :warning) and :message.
      def call_routing_issues
        CHECKS.select { |check| send(check[:check]) }.
          map { |check| check.slice(:key, :severity, :message) }
      end

      def call_routing_blocking_issues
        call_routing_issues.select { |issue| issue[:severity] == :blocking }
      end

      def call_routing_ready?
        call_routing_issues.empty?
      end
    end
  end
end
