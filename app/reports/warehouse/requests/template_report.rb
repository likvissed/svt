require 'prawn'

module Warehouse
  module Requests
    class TemplateReport < Prawn::Document
      def to_pdf(request_params)
        font_families.update('Times_New_Roman' => {
                               normal: Rails.root.join('app/assets/fonts/Times_New_Roman.ttf'),
                               bold: Rails.root.join('app/assets/fonts/Times_New_Roman_bold.ttf')
                             })
        font 'Times_New_Roman', size: 12

        move_down 2
        text 'Заявка на получение вычислительной техники', align: :center, style: :bold

        text "Заявка в ЛК № #{request_params['number_***REMOVED***']}", align: :right

        move_down 10
        text 'Данные заявки:'
        move_down 5
        table_items = []
        table_items << ['Наименование', 'Описание', 'Инв.№', 'Количество', 'Обоснование']

        request_params['request_items'].each do |it|
          table_items << [it['name'], it['description'], it['invent_num'], it['count'], it['reason']]
        end
        table table_items, cell_style: { inline_format: true, padding: [10, 10, 10, 10] } do # width: 180
          columns(-5).align = :center
          columns(-5).width = 100

          columns(-4).align = :center
          columns(-4).width = 170

          columns(-3).align = :center
          columns(-3).width = 70

          columns(-2).align = :center
          columns(-2).width = 80

          columns(-1).align = :center
          columns(-1).width = 120
        end

        move_down 30
        text 'Список рекомендаций:', align: :center, style: :bold
        move_down 15

        table_data = []
        request_params['recommendation_json'].each_with_index do |rec, index|
          table_data << [
            {
              content: "#{index + 1}"
            },
            {
              content: "#{rec['name']}", inline_format: true
            }
          ]
        end
        table table_data, cell_style: { inline_format: true, padding: [10, 10, 10, 10] } do # width: 180
          columns(-2).width = 30
          columns(-1).width = 510
        end

        move_down 20
        unless request_params['comment'].nil?
          text "<font size=\"12\"> <b> Комментарий: </b> </font> <font size=\"12\"> #{request_params['comment']} </font>", inline_format: true
        end

        stroke do
          move_down 15
          horizontal_rule
        end

        move_down 20
        text "Ответственный: #{request_params['user_fio']}"
        move_down 10
        text "Подразделение: #{request_params['user_dept']}"

        render
      end
    end
  end
end
