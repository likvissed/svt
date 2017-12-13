require 'csv'

module Invent
  module WorkplaceCounts
    # Создать список отделов и ответственных лиц из загруженного файла.
    class CreateList < Invent::ApplicationService
      def initialize(file)
        @file = file
        @flag = nil
        @obj_template = {
          division: nil,
          time_start: nil,
          time_end: nil,
          users_attributes: []
        }
      end

      def run
        validate_format
        parse_file

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      # Проверка формата загруженного файла (разрешен только CSV файл).
      def validate_format
        return if @file.content_type == 'text/csv'

        errors.add(:base, 'Неверный формат файла')
        raise 'abort'
      end

      # Обработка файла.
      def parse_file
        count = 0
        CSV.foreach(@file.path, headers: true, col_sep: '|', quote_char: '^') do |row|
          Rails.logger.info "НОВЫЙ ШАГ ЦИКЛА: #{count}".red
          data = row.to_hash
          Rails.logger.info 'Подраздение: %-5s ФИО: %-45s Таб №: %s' % [data['Подр.'], data['Уполномоченный'], data['Таб №']]
          unless data['Подр.'] && data['Таб №']
            Rails.logger.info 'Пропуск шага цикла. В файле не все данные.'.red
            next
          end

          @saving_obj = {}
          @user_obj = WorkplaceCount.user_attr_template(data['Таб №'])

          if WorkplaceCount.exists?(division: data['Подр.'])
            Rails.logger.info "Отдел #{data['Подр.']} уже существует. Редактирование".red
            @flag = 'edit'
            @workplace_count = WorkplaceCount.includes(:users).find_by(division: data['Подр.'])
            @saving_obj[:users_attributes] = @workplace_count.as_json(include: :users)['users'].map!(&:symbolize_keys)

            next if @workplace_count.users.any? { |user| user[:tn] == data['Таб №'].to_i }
          else
            @flag = 'new'
            @saving_obj = @obj_template.deep_dup
            @saving_obj[:division] = data['Подр.']
            @saving_obj[:time_start] = WorkplaceCount::ACCESS_TIME[:start]
            @saving_obj[:time_end] = WorkplaceCount::ACCESS_TIME[:end]
          end
          @saving_obj[:users_attributes] << @user_obj
          load_chief(data['Подр.'])

          Rails.logger.info "Результирующий хэш: #{@saving_obj.inspect}"

          save_workplace_count_list
          count += 1
        end
      end

      def load_chief(dept)
        dept = dept_chiefs(dept) until dept.nil?
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.info e.message.green
        Rails.logger.info 'Поиск начальников вручную'.green

        all_chiefs(dept)
      end

      def dept_chiefs(dept)
        data = Netadmin.get_dept_chiefs(dept)
        Rails.logger.info "Процедура получения данных о начальниках отдела '#{dept}': #{data.inspect}".green
        add_chief(dept, data[:dept_chief_tn])
        data[:top_dept]
      end

      # Получить список начальников и добавить в создаваемый объект
      def all_chiefs(dept)
        UserIss.where(dept: dept).each do |user|
          next unless Netadmin.user_chief?(user.tn)

          Rails.logger.info "Найден начальник отдела '#{dept}'. Таб. №: #{user.tn}".green
          add_chief(dept, user.tn)
        end
      end

      # Добавить начальника (если он еще не существует) к указанному отделу
      def add_chief(dept, tn)
        if @saving_obj[:users_attributes].any? { |user| user[:tn] == tn.to_i }
          Rails.logger.info 'Начальник уже задан в массиве'.red
          return
        end

        @saving_obj[:users_attributes] << WorkplaceCount.user_attr_template(tn)
        Rails.logger.info "Начальник с табельным #{tn} к отделу '#{dept}' добавлен".green
      end

      # Сохранение данных
      def save_workplace_count_list
        if @flag == 'new'
          Rails.logger.info "Создание записи (отдел: #{@saving_obj[:division]})".red
          @data = WorkplaceCount.new(@saving_obj)
          unless @data.save
            errors.add(:base, @data.errors.full_messages.join('. '))
            errors.add(:base, 'После загрузите файл заново')
            Rails.logger.info "Errors: #{data.errors.full_messages}".red
            raise 'abort'
          end
        else
          Rails.logger.info "Обновление записи (отдел: #{@workplace_count.division})".red
          unless @workplace_count.update_attributes(@saving_obj)
            errors.add(:base, @data.errors.full_messages.join('. '))
            errors.add(:base, 'После загрузите файл заново')
            Rails.logger.info "Errors: #{@workplace_count.errors.full_messages}".red
            raise 'abort'
          end
        end
      end
    end
  end
end
