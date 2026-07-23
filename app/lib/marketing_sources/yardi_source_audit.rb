module MarketingSources
  # Verifies that Marketing Sources with a tracking phone number have an
  # exactly (1:1) matching marketing source name in Yardi Voyager. Phone
  # leads are attributed in Voyager via the GuestCard TransactionSource,
  # which is the lead referral (the Marketing Source name); Voyager rejects
  # unknown names and the lead falls back to the 'Bluesky' source.
  #
  # audit_property is the single entrypoint (with retry) used by both the
  # MarketingSource save trigger (one property) and the daily scheduler
  # task (all active properties).
  class YardiSourceAudit
    MAX_ATTEMPTS = 3
    RETRY_WAIT = 15 # seconds, multiplied by attempt number

    # Audit one property, or all active properties when none is given.
    # Returns an Array of per-property result Hashes.
    def call(property: nil)
      properties = property.present? ? [property] : Property.active.order(:name)
      properties.map { |p| audit_property(p) }
    end

    # Audit a single property's marketing sources against Voyager, with
    # retries on API failure. Flags are only updated after a successful
    # fetch; an API failure leaves the previous audit state untouched.
    def audit_property(property)
      code = property.voyager_property_code
      return { property: property.name, skipped: 'No Voyager property code' } if code.blank?

      attempts = 0
      begin
        attempts += 1
        yardi_names = adapter.getMarketingSources(code)
      rescue StandardError => e
        if attempts < MAX_ATTEMPTS
          sleep(RETRY_WAIT * attempts)
          retry
        end
        msg = "MarketingSources::YardiSourceAudit failed for #{property.name} (#{code}) " \
              "after #{attempts} attempts: #{e}"
        Rails.logger.error(msg)
        Note.create(content: msg, classification: :error, notable: property)
        return { property: property.name, error: e.to_s, attempts: attempts }
      end

      missing = []
      checked_at = DateTime.current
      MarketingSource.where(property_id: property.id).each do |source|
        source_missing = source.tracking_number.present? && !yardi_names.include?(source.name)
        source.update_columns(yardi_source_missing: source_missing, yardi_source_checked_at: checked_at)
        missing << source.name if source_missing
      end

      if missing.any?
        msg = "MarketingSources::YardiSourceAudit: Voyager (#{code}) has no marketing source " \
              "exactly matching: #{missing.join(', ')}. Phone leads for these will fall back " \
              "to the 'Bluesky' source in Voyager."
        Rails.logger.warn(msg)
        Note.create(content: msg, classification: :error, notable: property)
      end

      { property: property.name, missing: missing, checked: yardi_names.size }
    end

    private

    def adapter
      @adapter ||= Yardi::Voyager::Api::GuestCards.new
    end
  end
end
