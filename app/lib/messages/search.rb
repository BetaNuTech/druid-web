module Messages
  class Search
    include ActiveModel::Model

    DEFAULT_OPTIONS = {
      unread: false,
      #sort_by: :date,
      #sort_dir: :desc,
      paginate: true,
      page: 1
    }

    VALID_OPTIONS = DEFAULT_OPTIONS.keys.freeze
    TRUE_VALUES = [true, 'true', 't', 'T', 1, '1'].freeze


    def initialize(params: nil, scope: nil, user: nil)
      @user = user
      @scope = base_scope(scope: scope, user: @user)
      @options = filter_params(params.dup)
    end

    def model_name
      ActiveModel::Name.new(self, nil, 'Message')
    end

    def call
      skope = @scope
      skope = apply_includes(skope)
      skope = apply_filters(skope)
      skope = apply_sort(skope)
      skope = apply_pagination(skope)

      skope
    end

    def pagination_params
      {
        message: {
          unread: unread
        }
      }
    end

    def unread
      TRUE_VALUES.include?(@options[:unread])
    end

    def unread=(value)
      @options[:unread] = TRUE_VALUES.include?(value)
    end

    def page
      @options[:page]
    end

    def page=(value)
      @options[:page] = [1, (value || 1).to_i ].max
    end

    private

    def apply_filters(skope)
      skope = skope.where(messages: {read_at: nil, incoming: true}) if unread
      skope
    end

    def apply_sort(skope)
      # TODO: sort by options

      # Sort by date descending
      skope.order(Arel.sql("COALESCE(messages.delivered_at, messages.updated_at) DESC"))
    end

    def apply_pagination(skope)
      paginate? ? skope.page(@options[:page]) : skope
    end

    def apply_includes(skope)
      skope.includes([:messageable, :message_type, :deliveries])
    end

    def paginate?
      TRUE_VALUES.include?(@options[:paginate])
    end

    def filter_params(in_params)
      in_params.permit! if in_params.respond_to?(:permit!)
      namespaced = in_params.fetch(:message, nil).present?
      if namespaced 
        params = in_params[:message]
        if in_params.fetch(:page,nil).present?
          params[:page] = in_params[:page]
        end
      end

      DEFAULT_OPTIONS.merge(( params||{} ).to_h.symbolize_keys).
        slice(*VALID_OPTIONS)
    end

    def base_scope(scope: nil, user: nil)
      # Extracted from MessagePolicy::IndexScope
      skope = scope || Message
      skope = case user
      when ->(u) { u.admin? }
        if user.monitor_all_messages?
          skope.for_leads
        else
          skope.where(user_id: user.id)
        end
      when nil
        Message
      else
        if user.monitor_all_messages?
          property_skope = skope.for_leads
          property_skope.where(user_id: user.id).or(property_skope.where(leads: {property_id: user.property_ids}))
        else
          skope.where(user_id: user.id)
        end
      end
    end
  end
end
