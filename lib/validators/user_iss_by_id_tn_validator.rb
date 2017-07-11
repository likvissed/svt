class UserIssByIdTnValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if UserIss.find_by(id_tn: value.to_i).nil?
      record.errors.add(attribute, options[:message] || :user_iss_by_id_tn)
    end
  end
end
