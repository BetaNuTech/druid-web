module ScheduledActions
  module Article
    extend ActiveSupport::Concern

    included do
      # Referenced object (i.e. a Unit for a Unit showing)
      attr_accessor :do_cleanup
      belongs_to :article, polymorphic: true, optional: true
      before_update :action_article_cleanup

      SUPPORTED_ARTICLES = [
        {
          class: 'Unit',
          record_descriptor: :display_name,
          action: LeadAction.showing&.name,
          prompt: '-- Select Unit to Show --',
          options_grouped: true,
          options: -> ( current_user:, target:, vacant: true, grouped: false ) {
            units = []
            skope = Unit
            case target
            when Lead
              skope = skope.where(property_id: target.property_id)
            when Property
              skope = skope.where(property_id: target.id)
            end
            if vacant
              collection = skope.vacant
            else
              collection = skope.order(unit: :asc)
            end
            if grouped
              model_units = collection.select{|u| u.model?}
              non_model_units = collection.select{|u| !u.model?}
              # Group by 'model' status
              {
                'Model': model_units,
                'Vacant': non_model_units
              }
            else
              collection
            end
          }
        }
      ]

      def action_article_cleanup
        return if do_cleanup == false
        unless article_selectable?
          self.article = nil
        end
        return true
      end

      def article_select_config(action: nil)
        case action
        when String
          action_record = LeadAction.where(name: action).first
        when LeadAction
          action_record = action
        when nil
          action_record = lead_action
        else
          action_record = nil
        end
        action_name = action_record&.name
        return SUPPORTED_ARTICLES.select{|sa| sa[:action] == action_name}.first
      end

      def article_selectable?(action: nil)
        !article_select_config(action: action).nil?
      end
    end
  end
end
