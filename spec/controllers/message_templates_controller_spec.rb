require 'rails_helper'

RSpec.describe MessageTemplatesController, type: :controller do
  include_context 'users'
  include_context 'messaging'
  include_context 'message_templates'
  render_views

  describe "GET #index" do
    describe "as an admin" do
      it "returns a success response" do
        sign_in administrator
        get :index, params: {}
        expect(response).to be_successful
      end
    end
    describe "as a corporate user" do
      it "returns a success response" do
        sign_in corporate
        get :index, params: {}
        expect(response).to be_successful
      end
    end
    describe "as property manager" do
      it "returns a success response" do
        sign_in property1_manager1
        get :index, params: {}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "returns a success response" do
        sign_in property1_agent1
        get :index, params: {}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        get :show, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
    describe "as a corporate user" do
      it "returns a success response" do
        sign_in corporate
        get :show, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
    describe "as a property manager" do
      it "returns a success response" do
        sign_in property1_manager1
        get :show, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "returns a success response" do
        sign_in property1_agent1
        get :show, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #edit" do
    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        get :edit, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
    describe "as a corporate user" do
      it "returns a success response" do
        sign_in corporate
        get :edit, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
    describe "as a property manager" do
      it "returns a success response" do
        sign_in property1_manager1
        get :edit, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "returns a success response" do
        sign_in property1_agent1
        get :edit, params: {id: agent1_shared_email_template}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #new" do
    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        get :new, params: {}
        expect(response).to be_successful
      end
    end
    describe "as a corporate user" do
      it "returns a success response" do
        sign_in corporate
        get :new, params: {}
        expect(response).to be_successful
      end
    end
    describe "as a property manager" do
      it "returns a success response" do
        sign_in property1_manager1
        get :new, params: {}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "returns a success response" do
        sign_in property1_agent1
        get :new, params: {}
        expect(response).to be_successful
      end
    end
  end
  describe "POST #create" do
    let(:valid_attributes) { attributes_for(:message_template).merge({ message_type_id: email_message_type.id }) }
    let(:invalid_attributes) { valid_attributes.merge({body: nil, subject: nil}) }
    describe "as an administrator" do
      it "creates the message template" do
        count = MessageTemplate.count
        sign_in administrator
        post :create, params: { message_template: valid_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        expect(MessageTemplate.count).to eq(count + 1)
      end
    end
    describe "as a corporate user" do
      it "creates the message template" do
        count = MessageTemplate.count
        sign_in corporate
        post :create, params: { message_template: valid_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        expect(MessageTemplate.count).to eq(count + 1)
      end
    end
    describe "as a property manager" do
      it "creates the message template" do
        count = MessageTemplate.count
        sign_in property1_manager1
        post :create, params: { message_template: valid_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        expect(MessageTemplate.count).to eq(count + 1)
      end
    end
    describe "as an agent" do
      it "creates the message template" do
        count = MessageTemplate.count
        sign_in property1_agent1
        post :create, params: { message_template: valid_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        expect(MessageTemplate.count).to eq(count + 1)
      end
    end
    describe "with invalid attributes" do
      it "redirects to the #new view" do
        count = MessageTemplate.count
        sign_in property1_agent1
        post :create, params: { message_template: invalid_attributes }
        expect(response).to be_successful
        expect(response).to render_template(:new)
        expect(MessageTemplate.count).to eq(count)
      end
    end
  end

  describe "UPDATE #update" do
    let(:valid_attributes) {
      attributes_for(:message_template).merge({
        message_type_id: email_message_type.id })
    }
    let(:updated_message_template_body) { 'Updated Body' }
    let(:new_attributes) { { body: updated_message_template_body } }
    let(:invalid_attributes) { { body: nil, subject: nil } }

    describe "as an administrator" do
      it "should update the message template" do
        sign_in administrator
        put :update, params: {id: agent1_shared_email_template.id, message_template: new_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        agent1_shared_email_template.reload
        expect(agent1_shared_email_template.body).to eq(updated_message_template_body)
      end
    end
    describe "as a corporate user" do
      it "should update the message template" do
        sign_in corporate
        put :update, params: {id: agent1_shared_email_template.id, message_template: new_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        agent1_shared_email_template.reload
        expect(agent1_shared_email_template.body).to eq(updated_message_template_body)
      end
    end
    describe "as a property manager" do
      it "should update the message template" do
        sign_in property1_manager1
        put :update, params: {id: agent1_shared_email_template.id, message_template: new_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        agent1_shared_email_template.reload
        expect(agent1_shared_email_template.body).to eq(updated_message_template_body)
      end
    end
    describe "as an agent" do
      it "should update the message template" do
        sign_in property1_agent1
        put :update, params: {id: agent1_shared_email_template.id, message_template: new_attributes }
        expect(response).to redirect_to(message_template_path(assigns[:message_template]))
        agent1_shared_email_template.reload
        expect(agent1_shared_email_template.body).to eq(updated_message_template_body)
      end
    end
    describe "with invalid params" do
      it "should display the form again" do
        initial_body = agent1_shared_email_template.body
        sign_in property1_agent1
        put :update, params: {id: agent1_shared_email_template.id, message_template: invalid_attributes }
        expect(response).to render_template(:edit)
        agent1_shared_email_template.reload
        expect(agent1_shared_email_template.body).to eq(initial_body)
      end
    end

  end
  describe "DELETE #destroy" do
    describe "as an agent" do
      it "should delete the message template" do
        sign_in property1_agent1
        count = MessageTemplate.count
        delete :destroy, params: {id: agent1_shared_email_template.id}
        expect(response).to redirect_to(message_templates_path)
        expect(MessageTemplate.count).to eq(count - 1)
      end
    end
  end

end
