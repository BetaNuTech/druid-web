require 'rails_helper'

RSpec.describe NotePolicy do
  include_context "users"
  include_context "messaging"

  describe "policy" do
    let(:note) { create(:note) }

    describe "for admins" do
      let(:policy) { NotePolicy.new(administrator, note)}

      it "allows #index" do
        assert policy.index?
      end

      it "allows #new" do
        assert policy.new?
      end

      it "allows #create" do
        assert policy.create?
      end

      it "allows #edit" do
        assert policy.edit?
      end

      it "allows #show" do
        assert policy.show?
      end

      it "alllows #update" do
        assert policy.update?
      end

      it "allows #destroy" do
        assert policy.destroy?
      end

      it "allows all params" do
        allowed_params = Note::ALLOWED_PARAMS
        expect(policy.allowed_params).to eq(allowed_params)
      end
    end

    describe "for agents" do
      let(:policy) { NotePolicy.new(agent, note)}

      it "disallows #index" do
        refute policy.index?
      end

      it "allows #new" do
        assert policy.new?
      end

      it "allows #create" do
        assert policy.create?
      end

      it "disallows #edit if not the owner" do
        refute policy.edit?
      end

      it "allowed #edit if the owner" do
        note.user = agent
        note.save
        policy = NotePolicy.new(agent, note)
        assert policy.edit?
      end

      it "allows #show" do
        assert policy.show?
      end

      it "disallows #update if not the owner" do
        refute policy.update?
      end

      it "allowed #update if the owner" do
        note.user = agent
        note.save
        policy = NotePolicy.new(agent, note)
        assert policy.update?
      end

      it "disallows #destroy if not the owner" do
        refute policy.destroy?
      end

      it "allowed #destroy if the owner" do
        note.user = agent
        note.save
        policy = NotePolicy.new(agent, note)
        assert policy.destroy?
      end

      it "allows all params if the owner" do
        note.user = agent
        note.save
        policy = NotePolicy.new(agent, note)
        allowed_params = Note::ALLOWED_PARAMS
        expect(policy.allowed_params).to eq(allowed_params)
      end

      it "disallowes user_id param if not the owner and not an admin" do
        allowed_params = Note::ALLOWED_PARAMS - [:user_id]
        expect(policy.allowed_params).to eq(allowed_params)
      end
    end

    describe "for unroled users" do
      let(:note) { create(:note, user: unroled_user) }
      let(:policy) { NotePolicy.new(unroled_user, note) }

      it "disallows everything even if somehow the owner" do
        refute policy.index?
        refute policy.new?
        refute policy.show?
        refute policy.edit?
        refute policy.update?
        refute policy.destroy?
        assert policy.allowed_params.empty?
      end

    end
  end
end
