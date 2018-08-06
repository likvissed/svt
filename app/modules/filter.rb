module Filter
  def filter(filtering_params = [])
    result = where(nil)

    filtering_params.each do |key, value|
      next if key.blank?

      if value.class.name == 'Array'
        value.each { |v| result = result.send(key, v) }
      elsif value.present?
        result = result.send(key, value)
      end
    end

    result
  end
end
