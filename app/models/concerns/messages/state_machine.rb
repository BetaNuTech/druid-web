module Messages
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        Message.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      include AASM

      validates :state, presence: true

      scope :drafts, -> {where(state: 'draft')}
      scope :sent, -> {where(state: 'sent')}

      aasm column: :state do
        state :draft, initial: true
        state :sent
        state :failed

        event :deliver do
          transitions from: [ :draft, :failed ], to: :sent, after: [:mark_as_read_by_sender, :perform_delivery]
        end

        event :fail do
          transitions from: [:draft, :sent ], to: :failed
        end
      end
    end
  end
end
