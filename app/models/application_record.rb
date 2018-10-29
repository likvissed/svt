class ApplicationRecord < ActiveRecord::Base
  extend Filter

  self.abstract_class = true

  RECORD_LIMIT = 400

  # Перевести указанный ключ enum.
  # type - имя переводимого поля (в ед. числе)
  # key - переводимое значение
  def self.translate_enum(type, key)
    status = I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{type.to_s.pluralize}.#{key}")
  end
end
