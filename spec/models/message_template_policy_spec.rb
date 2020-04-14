require 'rails_helper'

RSpec.describe MessageTemplatePolicy do
  include_context 'users'
  include_context 'messaging'
  include_context 'message_templates'

  describe "Scope" do

    describe "for admins" do
      it "should return all message templates" do
        scope = MessageTemplatePolicy::Scope.new(corporate, MessageTemplate)
        results = scope.resolve
        expect(results.count).to eq(MessageTemplate.count)
      end
    end

    describe "for managers" do
      it "should return all shared templates and private templates belonging to subordinates" #do
        #scope = MessageTemplatePolicy::Scope.new(property1_manager1, MessageTemplate)
        #results = scope.resolve
        #expect(results.to_a.sort).to eq(( all_message_templates - [ agent2_private_template ] ).sort)
      #end
    end

    describe "for agents" do
      it "should return all shared templates and own private templates" # do
        #scope = MessageTemplatePolicy::Scope.new(property1_agent1, MessageTemplate)
        #results = scope.resolve
        #expect(results.to_a.sort).to eq(
          #[
            #manager1_shared_email_template,
            #manager1_shared_sms_template,
            #agent1_shared_email_template,
            #agent1_shared_sms_template,
            #agent1_private_template,
            #agent2_shared_email_template,
            #agent2_shared_sms_template
          #].sort)
      #end
    end
  end

  describe "Controller Action policies" do

    describe "index?" do
      it "should permit admins" do
        policy = MessageTemplatePolicy.new(corporate, MessageTemplate)
        assert(policy.index?)
      end

      it "should permit any user" do
        policy = MessageTemplatePolicy.new(property1_manager1, MessageTemplate)
        assert(policy.index?)
        policy = MessageTemplatePolicy.new(property1_agent1, MessageTemplate)
        assert(policy.index?)
        policy = MessageTemplatePolicy.new(property2_agent2, MessageTemplate)
        assert(policy.index?)
      end
    end

    describe "new?" do
      it "should permit admins" do
        policy = MessageTemplatePolicy.new(corporate, MessageTemplate)
        assert(policy.new?)
        assert(policy.create?)
      end

      it "should permit any user" do
        policy = MessageTemplatePolicy.new(property1_manager1, MessageTemplate)
        assert(policy.new?)
        assert(policy.create?)
        policy = MessageTemplatePolicy.new(property1_agent1, MessageTemplate)
        assert(policy.new?)
        assert(policy.create?)
        policy = MessageTemplatePolicy.new(property2_agent2, MessageTemplate)
        assert(policy.new?)
        assert(policy.create?)
      end
    end

    describe "edit?/update?/destroy?" do
      describe "as an admin" do
        it "should allow editing others' shared message template" do
          policy = MessageTemplatePolicy.new(corporate, manager1_shared_email_template)
          assert(policy.edit?)
          assert(policy.update?)
          assert(policy.destroy?)
        end
        it "should allow editing others' private message template" do
          policy = MessageTemplatePolicy.new(corporate, manager1_private_template)
          assert(policy.edit?)
          assert(policy.update?)
          assert(policy.destroy?)
        end
      end

      describe "as a property manager" do
        it "should allow editing own message template" do
          policy = MessageTemplatePolicy.new(property1_manager1, manager1_private_template)
          assert(policy.edit?)
          assert(policy.update?)
          assert(policy.destroy?)
          policy = MessageTemplatePolicy.new(property1_manager1, manager1_shared_email_template)
          assert(policy.edit?)
          assert(policy.update?)
          assert(policy.destroy?)
        end
        it "should allow editing subordinates' message template" do
          policy = MessageTemplatePolicy.new(property1_manager1, agent1_private_template)
          assert(policy.edit?)
          assert(policy.update?)
          assert(policy.destroy?)
        end
        it "should disallow editing non-subordinates' message template" do
          policy = MessageTemplatePolicy.new(property1_manager1, agent2_private_template)
          refute(policy.edit?)
          refute(policy.update?)
          refute(policy.destroy?)
        end
      end

      describe "as an agent" do
        it "should allow editing own message template" do
          policy = MessageTemplatePolicy.new(property1_agent1, agent1_private_template)
          assert(policy.edit?)
          assert(policy.update?)
          assert(policy.destroy?)
          policy = MessageTemplatePolicy.new(property1_agent1, agent1_shared_email_template)
          assert(policy.edit?)
          assert(policy.update?)
          assert(policy.destroy?)
        end
        it "should disallow editing others' message template" do
          policy = MessageTemplatePolicy.new(property1_agent1, agent2_private_template)
          refute(policy.edit?)
          refute(policy.update?)
          refute(policy.destroy?)
        end
      end
    end

    describe "show?" do
      describe "as an admin" do
        it "should allow showing any users' message templates" do
          policy = MessageTemplatePolicy.new(corporate, agent1_shared_email_template)
          assert(policy.show?)
          policy = MessageTemplatePolicy.new(corporate, agent2_private_template)
          assert(policy.show?)
        end
      end

      describe "as a property manager" do
        it "should allow showing own templates" do
          policy = MessageTemplatePolicy.new(property1_manager1, manager1_private_template)
          assert(policy.show?)
          policy = MessageTemplatePolicy.new(property1_manager1, manager1_shared_email_template)
          assert(policy.show?)
        end
        it "should allow any shared template" do
          policy = MessageTemplatePolicy.new(property1_manager1, agent2_shared_sms_template)
          assert(policy.show?)
        end
        it "should allow showing subordinates' private templates" do
          policy = MessageTemplatePolicy.new(property1_manager1, agent1_private_template)
          assert(policy.show?)
        end
      end

      describe "as an agent" do
        it "should allow showing own templates" do
          policy = MessageTemplatePolicy.new(property1_agent1, agent1_private_template)
          assert(policy.show?)
        end
        it "should disallow showing others' private templates" do
          policy = MessageTemplatePolicy.new(property1_agent1, agent2_private_template)
          refute(policy.show?)
        end
      end

    end
  end

  describe "providing the helper" do

    describe "allowed_params" do
      describe "for an existing record" do
        describe "as an admin" do
          it "includes all possible params" do
            policy = MessageTemplatePolicy.new(corporate, agent1_private_template)
            expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS)
          end
        end
        describe "as a property manager" do
          describe "for a subordinate's message template" do
            it "includes all possible params" do
              policy = MessageTemplatePolicy.new(property1_manager1, agent1_private_template)
              expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS)
            end
          end
          describe "for a non-subordinate's message template" do
            it "excludes the user_id attribute" do
              policy = MessageTemplatePolicy.new(property1_manager1, agent2_shared_email_template)
              expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS - [:user_id])
            end
          end
        end
        describe "as an agent" do
          describe "for own message template" do
            it "includes all possible params" do
              policy = MessageTemplatePolicy.new(property1_agent1, agent1_private_template)
              expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS)
            end
          end
          describe "for another user's message template" do
            it "excludes the user_id attribute" do
              policy = MessageTemplatePolicy.new(property1_agent1, agent2_shared_email_template)
              expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS - [:user_id])
            end
          end
        end
      end
    end

    describe "for a new record" do
      describe "as an admin" do
        it "includes all possible params" do
          policy = MessageTemplatePolicy.new(corporate, MessageTemplate.new)
          expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS)
        end
      end
      describe "as a property manager" do
        it "includes all possible params" do
          policy = MessageTemplatePolicy.new(property1_manager1, MessageTemplate.new)
          expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS)
        end
      end
      describe "as an agent" do
        it "includes all possible params" do
          policy = MessageTemplatePolicy.new(property1_agent1, MessageTemplate.new)
          expect(policy.allowed_params).to eq(MessageTemplate::ALLOWED_PARAMS)
        end
      end
    end

    describe "users_for_reassignment" do

      describe "as an admin" do
        it "returns all users" do
          corporate
          property1_manager1
          property1_agent1
          property2_agent2
          policy = MessageTemplatePolicy.new(corporate, manager1_shared_email_template)
          expect(policy.users_for_reassignment.map(&:id).to_a.sort).to eq(User.all.map(&:id).sort)
        end
      end

      describe "as a property manager" do
        it "returns all the current_user's subordinates" do
          corporate
          property1_manager1
          property1_agent1
          property2_agent2
          policy = MessageTemplatePolicy.new(property1_manager1, manager1_shared_email_template)
          expect(policy.users_for_reassignment.map(&:id).to_a.sort).to eq(property1_manager1.subordinates.map(&:id).sort)
        end
      end

      describe "as an agent" do
        before(:each) do
          corporate
          property1_manager1
          property1_agent1
          property2_agent2
        end
        it "returns all members of the current_user's properties" do
          policy = MessageTemplatePolicy.new(property1_agent1, agent1_shared_email_template)
          expect(policy.users_for_reassignment.map(&:id).to_a.sort).to eq(property1_agent1.property.users.map(&:id).sort)
        end
      end
    end

  end

end
