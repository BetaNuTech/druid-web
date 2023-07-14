require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  include_context "users"
  include_context "team_members"
  render_views

  # This should return the minimal set of attributes required to create a valid
  # User. As you add validations to User, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:user).merge(
      profile_attributes: attributes_for(:user_profile)
    )
  }

  let(:invalid_attributes) {
    {
      email: 'invalid_email'
    }
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # UsersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        user = User.create! valid_attributes
        get :index, params: {}
        expect(response).to be_successful
        expect(response).to render_template("users/index")
      end
    end
    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        user = User.create! valid_attributes
        get :index, params: {}
        expect(response).to be_successful
        expect(response).to render_template("users/index")
      end
    end
    describe "as an agent" do
      it "allows access" do
        sign_in agent
        user = User.create! valid_attributes
        get :index, params: {}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        user = User.create! valid_attributes
        get :show, params: {id: user.to_param}
        expect(response).to be_successful
        expect(response).to render_template("users/show")
      end
    end
    describe "as an agent" do
      it "denies access" do
        sign_in agent
        user = User.create! valid_attributes
        get :show, params: {id: user.to_param}
        expect(response).to_not render_template("users/show")
        expect(response).to be_redirect
      end
    end
    describe "as the user" do
      it "returns a success response" do
        sign_in agent
        user = agent
        get :show, params: {id: user.to_param}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #new" do
    describe "as an admin" do
      it "returns a success response" do
        sign_in corporate
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
    describe "as a manager" do
      it "returns a success response" do
        sign_in manager
        get :new, params: {}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "denies access" do
        sign_in agent
        get :new, params: {}
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #edit" do
    let(:user) { team1_agent1 }
    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        get :edit, params: {id: user.to_param}
        expect(response).to be_successful
      end
    end
    describe "as a team lead" do
      it "returns a success response" do
        sign_in team1_lead1
        get :edit, params: {id: user.to_param}
        expect(response).to be_successful
      end
    end
    describe "as an unrelated team lead" do
      it "denies access" do
        user.membership.destroy
        sign_in team2_lead1
        get :edit, params: {id: user.to_param}
        expect(response).to be_redirect
      end
    end
    describe "as a property manager" do
      it "returns a success response" do
        manager.role = property_role
        manager.save!
        user.assignments.destroy_all
        manager.property.assign_user(user: user, role: 'agent')
        user.reload
        sign_in manager
        get :edit, params: {id: user.to_param}
        expect(response).to be_successful
      end
    end
    describe "as a manager at another property" do
      it "returns a success response when editing a member of a shared property" do
        user.property.assign_user(user: manager, role: 'manager')
        user.reload
        sign_in manager
        get :edit, params: {id: user.to_param}
        expect(response).to be_successful
      end

      it "denies access when editing a member of another property" do
        sign_in manager
        get :edit, params: {id: team2_agent1.to_param}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "denies access" do
        sign_in agent
        get :edit, params: {id: user.to_param}
        expect(response).to be_redirect
      end
    end
  end

  describe "POST #create" do
    describe "as an corporate" do
      describe "with valid params" do
        let(:valid_attributes_with_role) { valid_attributes.merge(role_id: property_role) }
        let(:valid_creation_attributes) { {user: valid_attributes_with_role, property_id: agent.property, property_role: 'agent', team_id: team1.id, teamrole_id: agent_teamrole.id } }

        it "creates a new User" do
          valid_creation_attributes
          sign_in corporate
          expect {
            post :create, params: valid_creation_attributes
          }.to change(User, :count).by(1)
        end

        it "redirects to the created user" do
          sign_in corporate
          post :create, params: valid_creation_attributes
          new_user = User.where(email: valid_attributes[:email]).order("created_at desc").last
          expect(response).to redirect_to(new_user)
        end

        it "assigns profile information" do
          sign_in corporate
          post :create, params: valid_creation_attributes
          new_user = User.where(email: valid_attributes[:email]).order("created_at desc").last
          expect(new_user.profile).to be_a(UserProfile)
          expect(new_user.profile.first_name).to_not be_nil
        end
      end
      describe "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          sign_in corporate
          post :create, params: {user: invalid_attributes}
          expect(response).to be_successful
        end
      end
    end
    describe "as an agent" do
      it "does not create a user" do
        sign_in agent
        expect {
          post :create, params: {user: valid_attributes}
        }.to change(User, :count).by(0)
      end
    end
  end

  describe "PUT #update" do
    let(:new_attributes) {
      pw = 'Foobar123.'
      {
        password: pw,
        password_confirmation: pw
      }
    }

    describe "as an administrator" do
      describe "with valid params" do
        it "updates the requested user" do
          sign_in administrator
          user = User.create! valid_attributes
          old_pw = user.encrypted_password
          put :update, params: {id: user.to_param, user: new_attributes}
          user.reload
          expect(user.encrypted_password).to_not eq(old_pw)
        end
      end
    end

    describe "as an corporate" do
      describe "with valid params" do

        it "updates the requested user" do
          sign_in corporate
          user = User.create! valid_attributes
          old_pw = user.encrypted_password
          put :update, params: {id: user.to_param, user: new_attributes}
          user.reload
          expect(user.encrypted_password).to_not eq(old_pw)
        end

        it "redirects to the user" do
          sign_in corporate
          user = User.create! valid_attributes
          put :update, params: {id: user.to_param, user: valid_attributes}
          expect(response).to redirect_to(edit_user_path(user))
        end

        it "can change the user role" do
          sign_in corporate
          user = User.create! valid_attributes
          user.role = property_role
          user.save!
          old_role = user.role_id
          put :update, params: {id: user.to_param, user: {role_id: corporate_role.id}}
          user.reload
        end

        it "cannot promote role to administrator" do
          sign_in corporate
          user = User.create! valid_attributes
          user.role = property_role
          user.save!
          old_role = user.role_id
          put :update, params: {id: user.to_param, user: {role_id: administrator_role.id}}
          user.reload
          expect(user.role_id).to eq(old_role)
          expect(user.role_id).to_not eq(administrator_role.id)
        end
      end

      describe "with invalid params" do
        it "returns a success response (i.e. to display the 'edit' template)" do
          sign_in corporate
          user = User.create! valid_attributes
          put :update, params: {id: user.to_param, user: invalid_attributes}
          expect(response).to be_successful
        end
      end

    end

    describe "as an agent" do
      describe "updating other record" do
        it "does not update the requested user" do
          sign_in agent
          user = User.create! valid_attributes
          old_pw = user.encrypted_password
          expect {
            put :update, params: {id: user.to_param, user: new_attributes}
            user.reload
          }.to_not change{user.encrypted_password}
        end
      end
      describe "updating own record" do
        it "updates the user" do
          sign_in agent
          user = agent
          old_pw = user.encrypted_password
          expect {
            put :update, params: {id: user.to_param, user: new_attributes}
            user.reload
          }.to change{user.encrypted_password}
        end

        it "will not update the role" do
          sign_in agent
          user = agent
          old_role = user.role_id
          expect {
            put :update, params: {id: user.to_param, user: {role_id: administrator_role.id}}
            user.reload
          }.to_not change{user.role_id}
        end
      end
    end
  end

  describe "DELETE #destroy" do
    it "does not delete the requested user" do
      sign_in corporate
      user = User.create! valid_attributes
      expect {
        delete :destroy, params: {id: user.to_param}
      }.to_not change(User, :count)
    end

    it "deactivates the user and prevents login" do
      user = User.create! valid_attributes
      sign_in user
      expect(response).to be_successful
      sign_out user
      sign_in corporate
      delete :destroy, params: {id: user.to_param}
      user.reload
      assert(user.deactivated?)
      sign_out user
      sign_in user
      get :index
      expect(response).to redirect_to('/auth/sign_in')
    end

    it "redirects to the users list" do
      sign_in corporate
      user = User.create! valid_attributes
      delete :destroy, params: {id: user.to_param}
      expect(response).to redirect_to(users_url)
    end
  end

end
