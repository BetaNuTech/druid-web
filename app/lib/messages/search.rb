# frozen_string_literal: true

module Messages
  class Search
    include ActiveModel::Model

    DEFAULT_OPTIONS = {
      unread: false,
      incoming: nil,
      outgoing: nil,
      failed: false,
      draft: false,
      mine: false,
      # sort_by: :date,
      # sort_dir: :desc,
      paginate: true,
      page: 1
    }.freeze

    VALID_OPTIONS = DEFAULT_OPTIONS.keys.freeze
    TRUE_VALUES = [true, 'true', 't', 'T', 1, '1'].freeze

    def initialize(params: nil, scope: nil, user: nil, current_property: nil)
      @user = user
      @current_property = current_property
      @scope = base_scope(scope: scope, user: @user, current_property: @current_property)
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
      apply_pagination(skope)
    end

    def pagination_params
      {
        message: {
          unread: unread,
          incoming: incoming,
          outgoing: outgoing,
          failed: failed,
          draft: draft,
          mine: mine
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
      @options[:page] = [1, (value || 1).to_i].max
    end

    def mine
      is_true?(@options[:mine])
    end

    def mine=(value)
      @options[:mine] = is_true?(value)
    end

    private

    def is_true?(value)
      TRUE_VALUES.include?(value)
    end

    def apply_filters(skope)
      if outgoing
        skope = skope.where(messages: { incoming: false })
      else
        skope = skope.where(messages: { read_at: nil, incoming: true }) if unread
        skope = skope.where(messages: { incoming: true }) if incoming && !unread
      end

      skope = skope.where(messages: { state: :failed }) if failed
      skope = skope.where(messages: { state: :draft }) if draft

      # Apply "mine" filter: messages I sent/received OR for leads assigned to me
      if mine && @user
        skope = skope.where('messages.user_id = ? OR leads.user_id = ?', @user.id, @user.id)
      end

      skope
    end

    def apply_sort(skope)
      # TODO: sort by options

      # Sort by date descending
      skope.order(Arel.sql('COALESCE(messages.delivered_at, messages.updated_at) DESC'))
    end

    def apply_pagination(skope)
      paginate? ? skope.page(@options[:page]) : skope
    end

    def apply_includes(skope)
      skope.includes(%i[messageable message_type deliveries])
    end

    def paginate?
      TRUE_VALUES.include?(@options[:paginate])
    end

    def filter_params(in_params)
      in_params.permit! if in_params.respond_to?(:permit!)
      namespaced = in_params.fetch(:message, nil).present?
      if namespaced
        params = in_params[:message]
        params[:page] = in_params[:page] if in_params.fetch(:page, nil).present?
      end

      DEFAULT_OPTIONS.merge((params || {}).to_h.symbolize_keys)
                     .slice(*VALID_OPTIONS)
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
      elsif incoming
        self.outgoing = false
        self.draft = false
        self.failed = false
      elsif outgoing
        self.unread = nil
        self.incoming = nil
      end
    end

    def base_scope(scope: nil, user: nil, current_property: nil)
      skope = scope || Message
      return Message if user.nil?

      # Agents see their own messages plus system user messages for their assigned or unassigned leads
      if user.agent?
        system_user_id = User.system&.id
        return skope.for_leads.where(leads: { property_id: user.property_ids })
                    .where('messages.user_id = ? OR (messages.user_id = ? AND (leads.user_id = ? OR leads.user_id IS NULL))',
                           user.id, system_user_id, user.id)
      end

      # For Managers, Corporate, and Admins: show all messages for selected property
      if current_property
        # If a specific property is selected, show all messages for that property
        skope.for_leads.where(leads: { property_id: current_property.id })
      elsif user.admin?
        # Admins with no property selected see all messages
        skope.for_leads
      else
        # Managers/Corporate with no property selected see all messages for their properties
        skope.for_leads.where(leads: { property_id: user.property_ids })
      end
    end
  end
end
