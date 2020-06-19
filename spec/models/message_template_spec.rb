# == Schema Information
#
# Table name: message_templates
#
#  id              :uuid             not null, primary key
#  message_type_id :uuid             not null
#  user_id         :uuid
#  name            :string           not null
#  subject         :string           not null
#  body            :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  shared          :boolean          default(TRUE)
#

require 'rails_helper'

RSpec.describe MessageTemplate, type: :model do
  it "can be initialized" do
    assert(create(:message_template).valid?)
  end

  describe :validations do
    let(:message_template) { create(:message_template, message_type: create(:email_message_type))}

    it "requires a name" do
      assert message_template.valid?
      message_template.name = nil
      refute message_template.valid?
    end
    it "requires a subject" do
      assert message_template.valid?
      message_template.subject = nil
      refute message_template.valid?
    end
    it "requires a body" do
      assert message_template.valid?
      message_template.body = nil
      refute message_template.valid?
    end
    it "has an optional user" do
      assert message_template.valid?
      message_template.user = nil
      assert message_template.valid?
    end
    it "has a message_type" do
      assert message_template.valid?
      message_template.message_type = nil
      refute message_template.valid?
    end
  end

  describe "rendering a template" do
    let(:template_subject_string) { "Subject {{user}}. ID: {{id}}" }
    let(:template_body_string) { "Body {{user}}. ID: {{id}}" }
    let(:message_template) {
      create(:message_template,
             message_type: create(:email_message_type),
             name: 'Test',
             subject: template_subject_string,
             body: template_body_string)
    }
    let(:invalid_body_message_template) {
      create(:message_template,
             message_type: create(:email_message_type),
             name: 'Test',
             subject: template_subject_string,
             body: "{{foobar")
    }
    let(:invalid_subject_message_template) {
      create(:message_template,
             message_type: create(:email_message_type),
             name: 'Test',
             subject: "{{foobar",
             body: template_body_string)
    }
    let(:template_data) { {'user' => 'JohnSmith', 'id' => 42}}

    it "renders the template subject with variable substitution" do
      output = message_template.render(template_data)
      #binding.pry
      refute output.errors?
      expect(output.subject).to eq("Subject JohnSmith. ID: 42")
    end

    it "renders the template body with variable substitution" do
      output = message_template.render(template_data)
      refute output.errors?
      expect(output.body).to match("Body JohnSmith. ID: 42")
    end

    it "returns errors in the body template" do
      output = invalid_body_message_template.render(template_data)
      assert output.errors?
      expect(output.errors.body.first).to match("MessageTemplate Rendering Error")
    end

    it "returns errors in the subject template" do
      output = invalid_subject_message_template.render(template_data)
      assert output.errors?
      expect(output.errors.subject.first).to match("MessageTemplate Rendering Error")
    end

    it "handles missing template data gracefully" do
      output = message_template.render({'id' => 42}) # missing user
      refute output.errors?
      expect(output.subject).to eq("Subject . ID: 42")
    end

    describe "using a layout" do
      let(:html_message_template) {
        create( :message_template,
                message_type: create(:email_message_type),
                subject: template_subject_string,
                body: template_body_string
              ) }
      let(:text_message_template) {
        create( :message_template,
                message_type: create(:sms_message_type),
                subject: template_subject_string,
                body: template_body_string
              ) }

      describe "for an HTML-supporting MessageType " do
        it "should use a pre-defined HTML layout" do
          output = html_message_template.render(template_data)
          refute output.errors?
          expect(output.layout).to eq('email.html.erb')
          expect(output.body).to match('html')
        end
      end

      describe "for a plain text MessageType" do
        it "should use a pre-defined text layout" do
          output = text_message_template.render(template_data)
          refute output.errors?
          expect(output.layout).to eq('sms.text.erb')
          expect(output.body).to_not match('html')
          expect(output.body).to match("Body JohnSmith. ID: 42")
        end
      end

    end
  end

end
