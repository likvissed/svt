module ModelMacros
  def skip_users_reference(**params)
    before do
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      allow_any_instance_of(UserIssByIdTnValidator).to receive(:validate_each)
    end
  end
end
