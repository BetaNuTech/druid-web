require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  include_context "users"
  include_context "messaging"
  render_views

  let(:email_message_body) { 'Test EMAIL message BODY' }
  let(:email_message_subject) { 'Test EMAIL message SUBJECT' }
  let(:message) {
    message = Message.new_message(
      message_type: email_message_type,
      from: agent, to: lead,
      body: email_message_body, subject: email_message_subject)
    message.save!; message }
  let(:lead) { create(:lead, user: agent, property: agent.property) }
  let(:email_message_template) { create(:message_template, message_type: email_message_type) }

  describe "GET #index" do
    it "should be successful" do
      message
      sign_in agent
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "should be successful" do
      sign_in agent
      get :show, params: {id: message.id}
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "should be successful" do
      sign_in agent
      get :new, params: {
        message_type_id: email_message_type,
        message_template_id: email_message_template.id,
        messageable_id: lead.id
      }
      expect(response).to be_successful
    end
    it "should be successful when composing a reply" do
      message.deliver!
      sign_in agent
      get :new, params: { reply_to: message.id }
      expect(response).to be_successful
    end
    it "should provide a message template" do
      sign_in agent
      get :new, params: {
        message_template_id: email_message_template.id,
        message_type_id: email_message_type.id,
        messageable_id: lead.id
      }
      expect(response).to be_successful
    end
  end

  describe "GET #body_preview" do
    it "should be successful when creating a new message" do
      sign_in agent
      get :body_preview, params: {message_id: message.id}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    it "should be successful" do
      message
      message_count = Message.count
      sign_in agent
      post :create, params: {
        message: {
          subject: 'Message subject',
          body: 'Message body',
          messageable_id: lead.id,
          messageable_type: 'Lead',
          recipientid: lead.email,
          message_type_id: email_message_type,
          message_template_id: MessageTemplate.email.last,
        }
      }
      expect(assigns[:message].errors).to be_empty
      expect(response).to redirect_to(message_path(assigns[:message]))
      expect(Message.count).to eq(message_count + 1)
    end

    it "can send immediately" do
      message
      message_count = Message.count
      sign_in agent
      post :create, params: {
        send_now: true,
        message: {
          subject: 'Message subject',
          body: 'Message body',
          messageable_id: lead.id,
          messageable_type: 'Lead',
          recipientid: lead.email,
          message_type_id: email_message_type,
          message_template_id: MessageTemplate.email.last,
        }
      }
      expect(assigns[:message].errors).to be_empty
      expect(response).to redirect_to(lead_path(lead))
      expect(Message.count).to eq(message_count + 1)
      expect(assigns[:message].state).to eq('sent')
    end

    it "handles an invalid submission" do
      sign_in agent
      post :create, params: {
        send_now: true,
        message: {
          subject: nil,
          body: 'Message body',
          messageable_id: lead.id,
          messageable_type: 'Lead',
          recipientid: lead.email,
          message_type_id: email_message_type,
          message_template_id: MessageTemplate.email.last,
        }
      }
      expect(assigns[:message].errors).to_not be_empty
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    it "should be successful" do
      sign_in agent
      get :edit, params: {id: message.id}
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    let(:new_subject) { 'Update Subject' }
    it "should be successful" do
      sign_in agent
      put :update, params: {id: message.id, message: {subject: new_subject}}
      expect(response).to be_redirect
      message.reload
      expect(message.subject).to eq(new_subject)
    end

    it "can send now" do
      sign_in agent
      put :update, params: {id: message.id, message: {subject: new_subject}, send_now: true}
      expect(response).to be_redirect
      message.reload
      expect(message.subject).to eq(new_subject)
      expect(message.state).to eq('sent')
    end

    it "can handle an invalid submission" do
      message.message_type = email_message_type
      message.save!
      sign_in agent
      put :update, params: {id: message.id, message: {body: nil}, }
      expect(response).to render_template(:edit)
    end
  end

  describe "POST #deliver" do
    it "should deliver the message" do
      sign_in agent
      expect(message.state).to eq('draft')
      post :deliver, params: {id: message.id}
      message.reload
      expect(message.state).to eq('sent')
    end
  end

  describe "POST #mark_read" do
    it "should mark the message read" do
      message
      sign_in agent
      refute(message.read?)
      post :mark_read, params: {message_id: message.id}
      message.reload
      assert(message.read?)
    end
  end

  describe "DELET #destroy" do
    it "should delete a message" do
      message
      sign_in agent
      expect{
        delete :destroy, params: {id: message.id}
      }.to change{ Message.count }
    end
  end
end
