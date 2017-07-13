class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Перевести указанный ключ enum.
  # type - имя переводимого поля (в ед. числе)
  # key - переводимое значение
  def self.translate_enum(type, key)
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{type.to_s.pluralize}.#{key}")
  end

  # Заменить названия месяцев для корректной работы ActiveRecord.
  def regexp_date(date)
    return if data.nil?
    date.gsub!(/января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря/,
               'января'    => 'Jan',
               'февраля'   => 'Feb',
               'марта'     => 'Mar',
               'апреля'    => 'Apr',
               'мая'       => 'May',
               'июня'      => 'Jun',
               'июля'      => 'Jul',
               'августа'   => 'Aug',
               'сентября'  => 'Sep',
               'октября'   => 'Oct',
               'ноября'    => 'Nov',
               'декабря'   => 'Dec')
    date.to_date
  end
end
