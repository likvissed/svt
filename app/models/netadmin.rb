class Netadmin < ApplicationRecord
  self.abstract_class = true
  establish_connection "#{Rails.env}_netadmin".to_sym

  def self.get_dept_chiefs(dept)
    data = establish_connection("#{Rails.env}_netadmin".to_sym).connection().exec_query("call get_dept_chiefs('#{dept}');").first
    clear_active_connections!
    data.nil? ? nil : data.symbolize_keys
  end

  def self.get_user_chiefs(tn)
    data = establish_connection("#{Rails.env}_netadmin".to_sym).connection().exec_query("call get_user_chiefs(#{tn});").first
    clear_active_connections!
    data.nil? ? nil : data.symbolize_keys
  end

  def self.user_chief?(tn)
    data = establish_connection("#{Rails.env}_netadmin".to_sym).connection().exec_query("call get_is_user_chief(#{tn});").first
    clear_active_connections!
    data['1'] == '1'
  end
end
