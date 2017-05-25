module Inventory
  class PcFile
    attr_reader :default_dir, :path_to_file_dir, :path_to_file

    def initialize(property_value_id, uploaded_file = nil)
      # Основная директория
      @default_dir = Rails.root.join('public', 'uploads', 'inventory')
      # Директория, содержащая записываемый файл
      @path_to_file_dir = @default_dir.join(property_value_id.to_s)
      # Записываемый файл
      @file = uploaded_file
    end

    def upload
      raise 'abort' if @file.nil?
      Rails.logger.info 'Получен файл для загрузки на сервер'.red

      prepare_to_upload
      save_file
    rescue RuntimeError
      false
    end

    def destroy
      Rails.logger.info "Удаление директории: #{@path_to_file_dir}".red

      FileUtils.rm_r(@path_to_file_dir) if File.exist?(@path_to_file_dir)
      true
    rescue
      false
    end

    private

    # Подготовка к записи файла
    def prepare_to_upload
      # Проверить, существует ли директория public/upload/inventory/<property_value_id>. Если нет - создать.
      FileUtils.mkdir_p(@path_to_file_dir) unless @path_to_file_dir.exist?

      # Удалить все существующие файлы из директории.
      Dir.foreach(@path_to_file_dir) do |file|
        FileUtils.rm_f("#{@path_to_file_dir}/#{file}") if file != '.' && file != '..'
      end
    end

    def save_file
      @path_to_file = @path_to_file_dir.join(@file.original_filename)

      File.open(@path_to_file, 'w:UTF-8:ASCII-8BIT') do |file|
        file.write(@file.read)
      end
    end
  end
end
