class ReferralBounceService
  DEFAULT_URL =  'https://www.bluestonemap.com/'.freeze
  NOTE_LEAD_ACTION = 'External Referral'.freeze
  NOTE_REASON = 'Lead Referral'.freeze
  NOTE_CLASSIFICATION = 'external'.freeze
  REQUEST_ATTRIBUTES = %w(api_token propertycode campaignid trackingid).freeze
  STATS_VERSION = 1

  def initialize(request=nil)
    @request = request
  end

  def create_bounce
    raise 'No controller request provided, this should be called from a Controller' unless @request.present?

    begin
      bounce_data = {
        propertycode: referral_bounce_params[:propertycode],
        campaignid: referral_bounce_params[:campaignid],
        trackingid: referral_bounce_params[:trackingid],
        referer: @request.referer || 'UNKNOWN'
      }

      lead_source = LeadSource.active.find_by(
        slug: 'adbounce', api_token: referral_bounce_params[:api_token])
      raise "ReferralBounce ERROR: LeadSource for token '#{referral_bounce_params[:api_token]}' not found!" if lead_source.nil?

      property = Property.with_yardi_code(referral_bounce_params[:propertycode])
      raise "ReferralBounce ERROR: Property with code '#{referral_bounce_params[:propertycode]}' not found!" if property.nil?

      website_url = property.website
      bounce_data[:property_id] = property.id

      bounce_record = property.referral_bounces.new(bounce_data)
      if bounce_record.valid?
        bounce_record.save
        create_event_note(data: bounce_data, property: property)
      else
        create_event_note(data: bounce_data.merge(bounce_record.errors.to_hash), property: property, classification: :error)
      end

      return website_url
    rescue => error
      ErrorNotification.send(error, bounce_data)
      return nil
    end
  end


  def stats_json
    # = Codegen begin
    #  Create a ruby method called stats_json
    #  Take the collection of all ReferralBounce records and create a list of unique campaignid values. This is the campaign list.
    #  This function will return a hash containing several keys: :version, :data, and :created_at.
    #    - The value of :version is assigned the value of the constant STATS_VERSION
    #    - The value of :created_at is the current time determined by the function 'Time.current'
    #    - The value of the :data key will contain a set of keys corresponding to the ids of all active Properties (fetch these with 'Property.active'). These are the parent properties.
    #     - The data stored in each of these property id keys will contain a hash with the following keys: property_id, property_name, referrals
    #       - The :referrals key value is a hash containing statistical data about ReferralBounce records associated with the parent property
    #       - Find the ReferralBounce records associated with the parent property
    #       - The :referrals data hash contains keys that correspond to the ReferralBounce creation timestamps, the key is formatted like 'MM/YY'. These are the date keys.
    #         - The date key values contain a hash with keys corresponding to each value of the campaign list. These are the campaign stats keys.
    #         - The value of each campaign stats key is an integer, the count of ReferralBounce records belonging to the parent property with a campaignid value that matches the campaign stats key during the month that corresponds to the date key.
    #     - Add another key to the :data hash called :totals
    #       - The :totals hash contains two keys called :campaigns, and :properties
    #        - The :campaigns key values contain a hash with keys corresponding to each value of the campaign list. These are the totals campaign stats keys.
    #          - The value of each campaign stats key is a hash with containing keys that correspond to the ReferralBounce creation timestamps, the key is formatted like 'MM/YY'. These are the campaign totals date keys.
    #            - The value of each date key is an integer, the count of ReferralBounce records with a campaignid matching the parent campaign stat key and a creation date during the month indicated by the parent campaign totals date key.
    #            - Add a key to the hash called :total, its value is the count of ReferralBounce records with a campaignid matching the parent campaign stat key
    #         - The :properties key value is a hash having the same parent property keys as mentioned earlier
    #           - The value of each property key is a hash with two keys: :property_name, :total
    #             - Fetch the active Property with the same id as the property key
    #             - The value of property_name is the Property name
    #             - The value of total is an integer, the count of ReferralBounce records associated with that property
    # After you create the method, refactor it to optimize performance.
    # =Codegen end

    campaign_list = ReferralBounce.pluck(:campaignid).uniq
    data = Hash.new { |h, k| h[k] = {} }

    data[:version] = STATS_VERSION
    data[:created_at] = Time.current

    Property.active.each do |property|
      property_data = {}
      property_data[:property_id] = property.id
      property_data[:property_name] = property.name
      property_data[:referrals] = {}

      ReferralBounce.where(property_id: property.id).each do |referral|
        date_key = referral.created_at.strftime("%m/%y")
        campaign_key = referral.campaignid

        property_data[:referrals][date_key] ||= {}
        property_data[:referrals][date_key][campaign_key] ||= 0
        property_data[:referrals][date_key][campaign_key] += 1
      end

      data[property.id] = property_data
    end

    totals = {
      campaigns: {},
      properties: {}
    }

    campaign_list.each do |campaign|
      totals[:campaigns][campaign] = {}

      ReferralBounce.where(campaignid: campaign).each do |referral|
        date_key = referral.created_at.strftime("%m/%y")
        property_key = referral.property_id

        totals[:campaigns][campaign][date_key] ||= {}
        totals[:campaigns][campaign][date_key][:total] ||= 0
        totals[:campaigns][campaign][date_key][:total] += 1

        totals[:campaigns][campaign][date_key][property_key] ||= 0
        totals[:campaigns][campaign][date_key][property_key] += 1

        totals[:properties][property_key] ||= {}
        totals[:properties][property_key][:property_name] ||= Property.find(property_key).name
        totals[:properties][property_key][:total] ||= 0
        totals[:properties][property_key][:total] += 1
      end
    end

    data[:totals] = totals

    return {
      version: data[:version],
      data: data,
      created_at: data[:created_at]
    }
  end


  def stats_array
    # =CodeGen begin
    #  Create a ruby method called stats_csv. This method outputs an array of arrays containing stats and counts for ReferralBounce records.
    #  Fetch a collection of ReferralBounce records created the past year, including their associated Property records. Group the records by campaignid and property and include the count of ReferralBounce records for that campaignid, property, and month.
    #  Sort the collection by ReferralBounce.campaignid, then Property Name, then creation date month and year
    #  Using the collection return an array of arrays
    #   - Each row contains the following values: campaignid, property name, creation date month (formatted as MM/YY), and total count of ReferralBounce records corresponding to the previous values
    #  Refactor this function to reduce the number of database calls.
    # =Codegen end

    referral_bounces = ReferralBounce.includes(:property)
      .where(created_at: 1.year.ago..Time.now)
      .group(:campaignid, :property_id, "DATE_TRUNC('month', referral_bounces.created_at)")
      .count

    properties = Property.where(id: referral_bounces.keys.map(&:second))
    property_names = properties.pluck(:id, :name).to_h

    referral_bounces.map do |(campaignid, property_id, month), count|
      property_name = property_names[property_id]
      month_formatted = month.strftime("%m/%y")
      [campaignid, property_name, month_formatted, count]
    end.sort_by { |row| [row[0], row[1], row[2]] }
  end

  private

  def referral_bounce_params
    @referral_bounce_params ||= @request.params.slice(*REQUEST_ATTRIBUTES)
  end

  def create_event_note(data: , property:, classification: :comment)
    lead_action = LeadAction.where(name: NOTE_LEAD_ACTION).first
    reason = Reason.where(name: NOTE_REASON).first
    notable = property
    content = "ReferralBounce occured for campaign #{data[:campaignid]} with tracking id #{data[:trackingid]}"

    Note.create(
      classification: classification,
      lead_action: lead_action,
      reason: reason,
      notable: notable,
      content: content
    )
  end

end
