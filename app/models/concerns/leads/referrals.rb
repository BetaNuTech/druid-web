module Leads
  module Referrals
    extend ActiveSupport::Concern

    included do
      has_many :referrals, dependent: :destroy, class_name: 'LeadReferral'
      accepts_nested_attributes_for :referrals, allow_destroy: true
      after_save :create_referral_comment

      SUPPORTED_REFERRALS = [
        {
          class: 'Resident',
          record_descriptor: :name_and_unit,
          referral: 'Resident',
          prompt: '-- Select Resident --',
          options_grouped: false,
          options: -> ( current_user:, property:, grouped: true ) {
            return [] unless property.present?
            collection = property.residents.
              includes(:unit).
              where(residents: {status: 'current'}). # We are only listing current residents
              order(last_name: :asc, first_name: :asc)
            if grouped
              return collection.group_by{|r| r.status.capitalize }
            else
              return collection
            end
          }
        }
      ]

      # Create missing
      def infer_referral_record
        return if self.errors&.any? || referral_missing? || referrals.any?
        referral_source = LeadReferralSource.where(name: self.referral).first
        lead_referral = LeadReferral.new(
          lead: self,
          lead_referral_source: referral_source,
          referrable: referral_source,
          note: self.referral
        )
        lead_referral.save
        return lead_referral
      end

      def referral_missing?
        return referral.nil? || referral.empty?
      end

      def referral_select_config(referral: nil)
        case referral
        when String
          lead_referral_source_name = LeadReferralSource.where(name: referral).first&.name
        when LeadReferral
          lead_referral_source_name = referral.lead_referral_source&.name
        else
          lead_referral_source_name = nil
        end
        return SUPPORTED_REFERRALS.select{|sa| sa[:referral] == lead_referral_source_name}.first
      end

      def referral_selectable?(referral: nil)
        !referral_select_config(referral: referral).nil?
      end

      # Create a Comment/Note for Referrals with a Referrable link
      def create_referral_comment
        referral_action = LeadAction.where(name: 'Resident Referral').first
        referral_reason = Reason.where(name: 'Referral').first

        # Return if necessary seed data is not present
        return true unless ( referral_action.present? && referral_reason.present? )

        # Return if there is already a Referral comment
        return true if comments.where(lead_action_id: referral_action.id).any?

        referrals.where("referrable_id IS NOT NULL").each do |referral|
          next unless referral.referrable.present?
          comment_content = "%s %s referred this Lead" % [referral.referrable_type, referral.referrable&.name]
          comment = Note.create( # create_event_note
            lead_action: referral_action,
            reason: referral_reason,
            notable: self,
            content: comment_content,
            classification: 'system'
          )
        end

        return true
      end

      def create_per_lead_marketing_expense
        if (fee = marketing_source_referral_fee)
          marketing_source.marketing_expenses.create(
            property_id: property_id,
            description: "Lead or showing marketing fee for #{name}",
            fee_total: fee,
            fee_type: 'lead',
            quantity: 1,
            start_date: Date.current,
            end_date: Date.current
          )
        end
      end

      def marketing_source_referral_fee
        marketing_source&.fee_rate
      end

      def marketing_source
        property.marketing_sources.current.where(name: referral, fee_type: 'lead').last
      end

    end

    class_methods do

      def infer_referral_records
        transaction do
          all.each(&:infer_referral_record!)
        end
      end

    end

  end
end
