class AddGoogleSignInToUsers < ActiveRecord::Migration[6.1]
  def change
    # Devise's OmniAuth convention: provider + uid identify the external identity.
    # uid is Google's `sub` claim -- stable for the life of the Google account,
    # and unlike the email address it does not change when someone is renamed.
    add_column :users, :provider, :string
    add_column :users, :uid, :string

    # The address Google asserted, recorded separately from users.email so an
    # admin editing users.email cannot silently repoint a linked identity.
    add_column :users, :google_email, :string
    add_column :users, :google_linked_at, :datetime

    # Shadow columns: what Google last told us the name was. Name sync diffs
    # against THESE, never against user_profiles.first_name/last_name -- see
    # Users::OmniauthCallbacksController#sync_name_from_google for why.
    add_column :users, :google_given_name, :string
    add_column :users, :google_family_name, :string

    # One Google identity may bind to at most one user. Without this a single
    # `sub` could be attached to several rows, and "which account does this
    # Google login mean?" would have more than one answer.
    add_index :users, %i[provider uid], unique: true
  end
end
