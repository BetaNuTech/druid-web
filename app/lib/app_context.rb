class AppContext
  BLACKLIST = [
    /^Api/,
    /^api/,
    /Devise/,
    /Users::/,
    /rails\/conductor/,
    /active_storage/,
    /^rails/,
    /action_mailbox/
  ]

  class << self

    def list0
      if (controllers = ApplicationController.descendants).empty?
        Rails.application.eager_load!
        controllers = ApplicationController.descendants
      end

      appcontexts = controllers.map do |controller|
        name  = controller.to_s
        [name] +
          controller.action_methods.to_a.map{|a| name + "#" + a }
      end.flatten

      return appcontexts.
        select{|a| !BLACKLIST.any?{|b| a.match(b)} }.
        sort
    end

    def list
      routes = Rails.application.routes.routes.
        map{ |r| { controller: r.defaults[:controller],
                   action: r.defaults[:action],
                   verb: r.verb } }
      useful_routes = routes.select{|r| r[:controller].present? &&
                                        !BLACKLIST.any?{|b| r[:controller].match?(b)} }
      controllers = useful_routes.map{|r| ( r[:controller] || '' ).camelcase + '#'}.uniq.compact
      actions = useful_routes.
        select{|r| r[:controller].present? }.
        map{|ac| ac[:controller].camelcase + "#" + ac[:action]}
      appcontexts = controllers + actions
      return appcontexts.sort.uniq
    end

    # List appcontexts for params containing :controller and :action keys
    def for_params(params)
      controller = params[:controller]
      action = params[:action] || ''
      return [] unless controller.present?
      return list.select do |appcontext|
        req_controller = controller.camelcase
        req_action = req_controller + '#' + action
        if action.present?
          req_action == appcontext ||
            ( req_controller + "#" ) == appcontext
        else
          appcontext.match(req_controller)
        end
      end
    end

    def accessible_to(user)
      return list_policies.to_a.inject({}) do |memo, obj|
        action, policy_desc = obj
        if policy_desc.present?
          policy, policy_action = policy_desc.split('#')
          policy = policy.constantize.new(user, nil)
          index_allowed = policy.index? rescue false
          if policy_action.present?
            action_allowed = policy.send(policy_action.to_sym) || index_allowed rescue index_allowed
          else
            action_allowed = index_allowed
          end
        else
          action_allowed = true
        end
        memo[action] = action_allowed || false
        memo
      end
    end

    def options_for_accessible_to(user)
      accessible_to(user).to_a.
        select{ |ac| ac.last}.
        map{ |ac|
          reference = ac.first
          ac_label = humanize_context(reference)
          [ ac_label, reference ]
        }
    end

    def list_policies
      return list.inject({}) do |memo, appcontext|
        policy = policy_for_action(appcontext)
        if policy.first
          memo[appcontext] = policy.join('#')
        else
          memo[appcontext] = nil
        end
        memo
      end
    end

    def humanize_context(context)
      controller, action = context.split('#')
      humanized_controller = (controller || '').underscore.humanize.titlecase
      humanized_action = ( action || 'General' ).humanize.titlecase
      ac_label = humanized_controller + ": " + humanized_action
      return ac_label
    end

    def policy_for_action(reference)
      controller_name, action_name = reference.split('#')
      policy_name = controller_name.underscore.singularize.camelcase + 'Policy'
      policy_action = nil
      if (policy = policy_name.constantize rescue nil)
        policy_action_name = ( action_name || 'index' ) + '?'
        if policy.new(nil, nil).respond_to?(policy_action_name)
          policy_action = policy_action_name
        end
      end
      return [policy, policy_action]
    end

  end
end
