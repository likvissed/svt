class UserIssByIdTnValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if UsersReference.info_users("id==#{value.to_i}").first.blank?
      record.errors.add(attribute, options[:message] || :user_iss_by_id_tn)
    end
  end
end
