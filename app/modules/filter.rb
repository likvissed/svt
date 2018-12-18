module Filter
  def filter(filtering_params = [])
    result = where(nil)

    filtering_params.each do |key, value|
      next if key.blank? || value.blank?

      result = result.send(key, value)
    end

    result
  end
end
