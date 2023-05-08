module Messages
  class Search
    include ActiveModel::Model

    DEFAULT_OPTIONS = {
      unread: false,
      incoming: nil,
      outgoing: nil,
      failed: false,
      draft: false,
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
      normalize_options
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
          unread: unread,
          incoming: incoming,
          outgoing: outgoing,
          failed: failed,
          draft: draft
        }
      }
    end

    def incoming
      is_true?(@options[:incoming])
    end

    def incoming=(value)
      @options[:incoming] = is_true?(value)
    end

    def outgoing
      is_true?(@options[:outgoing])
    end

    def outgoing=(value)
      @options[:outgoing] = is_true?(value)
    end

    def unread
      is_true?(@options[:unread])
    end

    def unread=(value)
      @options[:unread] = is_true?(value)
    end

    def failed
      is_true?(@options[:failed])
    end

    def failed=(value)
      @options[:failed] = is_true?(value)
    end

    def draft
      is_true?(@options[:draft])
    end

    def draft=(value)
      @options[:draft] = is_true?(value)
    end

    def page
      @options[:page]
    end

    def page=(value)
      @options[:page] = [1, (value || 1).to_i ].max
    end

    private

    def is_true?(value)
      TRUE_VALUES.include?(value)
    end

    def apply_filters(skope)
      if outgoing
        skope = skope.where(messages: {incoming: false}) 
      else
        skope = skope.where(messages: {read_at: nil, incoming: true}) if unread
        skope = skope.where(messages: {incoming: true}) if incoming && !unread
      end

      skope = skope.where(messages: {state: :failed}) if failed
      skope = skope.where(messages: {state: :draft}) if draft
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

    # Make options logically consistent
    def normalize_options
      if draft
        self.failed = false
        self.unread = false
        self.incoming = false
        self.outgoing = false
      end

      if failed
        self.draft = false
        self.incoming = false
        self.outgoing = true
        self.unread = false
      end

      if unread
        self.incoming = true
        self.outgoing = false
        self.failed = false
        self.draft = false
      else
        if incoming
          self.outgoing = false
          self.draft = false
          self.failed = false
        elsif outgoing
          self.unread = nil
          self.incoming = nil
        end
      end

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
        property_skope = skope.for_leads.where(leads: {property_id: user.property_ids})
        if user.monitor_all_messages?
          property_skope
        else
          property_skope.where(user_id: user.id)
        end
      end
    end
  end
end
