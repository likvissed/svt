<?php
include_once 'PHPRtfLite.php';
include_once 'DBConn.php';

// ============================================ Данные полученные от модели ============================================

$env = $argv[1] . '_invent';
$order_id = $argv[2];
$params = json_decode($argv[3], true);;
$database = yaml_parse_file('config/database.yml');

$con = new DBConn ($database[$env]);
$query = "
SELECT
  warehouse_orders.*, invent_item.*, invent_property_value.value as str_val, invent_property_list.short_description as list_val, invent_property.short_description as property, invent_type.short_description as type
FROM
  warehouse_orders
INNER JOIN
  warehouse_operations
ON
  warehouse_operations.operationable_id = warehouse_orders.id AND warehouse_operations.operationable_type = 'Warehouse::Order'
INNER JOIN
  warehouse_inv_item_to_operations
ON
  warehouse_inv_item_to_operations.operation_id = warehouse_operations.id
INNER JOIN
  invent_item
ON
  invent_item.item_id = warehouse_inv_item_to_operations.invent_item_id AND invent_item.item_id IN (";

$i = 0;
foreach($params as $par) {
  $query .= ':item_id' . $i . ',';
  $i++;
}
$query = preg_replace('/,$/', '', $query);

$query .= ')';
$query .= "
LEFT OUTER JOIN
  invent_property_value
ON
  invent_property_value.item_id = invent_item.item_id
LEFT OUTER JOIN
  invent_type
ON
  invent_item.type_id = invent_type.type_id
INNER JOIN
  invent_property
ON
  invent_property.property_id = invent_property_value.property_id AND invent_property.mandatory = true
LEFT OUTER JOIN
  invent_property_list
ON
  invent_property_list.property_list_id = invent_property_value.property_list_id
WHERE
  warehouse_orders.id = :order_id
ORDER BY
  invent_item.item_id";

$con->prepare_query($query);
$con->bind(':order_id', $order_id);
$i = 0;
foreach($params as $par) {
  $con->bind(":item_id$i", $par['item_id']);
  $i++;
}
$sql_data = $con->row_set();

// ============================================ Преобразование данных =================================================

$result = array();
$i = 0;
foreach($sql_data as $row_data) {
  $index = get_result_index($row_data, $result);
  if (is_null($index)) {
    $index = $i;
    $result[$index] = array();
    $i++;
  }

  $result[$index]['item_id'] = $row_data['item_id'];
  $result[$index]['type'] = $row_data['type'];

  if (!isset($result[$index]['invent_num'])) {
    foreach ($params as $par) {
      if ($par['item_id'] == $result[$index]['item_id']) {
        $result[$index]['invent_num'] = $par['invent_num'];
      }
    }
  }

  if (!isset($result[$index]['property_values'])) {
    $result[$index]['property_values'] = array();
  }

  array_push($result[$index]['property_values'], get_prop_val_object($row_data));
}

function get_prop_val_object($data) {
  $value = $data['list_val'] ? $data['list_val'] : $data['str_val'] ;

  return array(
    'property' => $data['property'],
    'value' => $value
  );
}

function get_result_index($current_row, $result) {
  $index = null;

  if (empty($result)) {
    return $index;
  }

  for ($j=0; $j<count($result); $j++) {
    if (!isset($result[$j])) {
      break;
    }

    if ($result[$j]['item_id'] == $current_row['item_id']) {
      $index = $j;
      break;
    }
  }

  return $index;
}

// ============================================ Инициализация страницы =================================================

PHPRtfLite::registerAutoloader();
$rtf = new PHPRtfLite(); //Основной класс
$rtf->setMargins(1.7, 0.8, 1, 1);
$table_font = new PHPRtfLite_Font(11, 'Times New Roman');
$footer_font = new PHPRtfLite_Font(12, 'Times New Roman');
$footer_underline_font = new PHPRtfLite_Font(12, 'Times New Roman');
$fontBold = new PHPRtfLite_Font(12, 'Times New Roman'); //Жирный шрифт
$fontBold->setBold();
$footer_underline_font->setUnderline();
$section = $rtf->addSection();

// ============================================ Контент ================================================================

$table = $section->addTable();

$rows = count($result);
$cols = 3;
$height = 3.0;
$mainBorder = new PHPRtfLite_Border_Format(1); //Формат барьера
$border = new PHPRtfLite_Border($rtf, $mainBorder, $mainBorder, $mainBorder, $mainBorder);

$table->addRows($rows, $height);
$table->addColumnsList(array(2.6, 12.7, 2.6));
$table->setBorderForCellRange($border, 1, 1, $rows, $cols);

$cell = $table->getCell(1, 2);

$i = 0;
foreach($result as $data) {
  $cell = $table->getCell($i + 1, 1);
  $cell->setBackgroundColor('#dddddd');

  $cell = $table->getCell($i + 1, 2);
  $cell->setCellPaddings(0.2, 0.2, 0.2, 0.2);

  $table->writeToCell($i + 1, 2, $data['type'] . "\n", $fontBold);
  foreach($data['property_values'] as $prop_val) {
    $table->writeToCell($i + 1, 2, $prop_val['property'] . ': ' . $prop_val['value'] . "\n", $table_font);
  }
  $table->writeToCell($i + 1, 3, 1, $table_font);

  $nested_table = $cell->addTable();
  $nested_table->addRows(3, 0.5);
  $nested_table->addColumnsList(array(6, 6));
  $nested_table->setBorderForCellRange($border, 1, 1, $rows, $cols);
  $nested_table->writeToCell(1, 1, ' ');
  $nested_table->writeToCell(1, 2, ' ');
  $nested_table->writeToCell(2, 1, ' ');
  $nested_table->writeToCell(2, 2, ' ');
  $nested_table->writeToCell(3, 1, 'Заявка', $table_font);
  $nested_table->writeToCell(3, 2, 'Инв № ' . $data['invent_num'], $table_font);

  $cell = $table->getCell($i + 1, 3);
  $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
  $cell->setVerticalAlignment(PHPRtfLite_Table_Cell::VERTICAL_ALIGN_CENTER);

  $i++;
}

$section->writeText('', $font, $tableFormat);

$table = $section->addTable();
$table->addRows(3, 1);
$table->addColumnsList(array(10.6, 7.3));

$cell = $table->getCell(1, 2);

$table->writeToCell(1, 1, 'Фамилия  _____________________', $footer_font);
$table->writeToCell(1, 2, 'Подпись  _____________________', $footer_font);
$table->writeToCell(2, 1, '"_____" "________________" 2018 г.', $footer_font);
$table->writeToCell(2, 2, 'Цех (Отд) ______ тел ___________', $footer_font);
$table->writeToCell(3, 1, 'Корпус  ________________', $footer_font);
$table->writeToCell(3, 2, 'Комната  ________________', $footer_font);

$rtf->sendRtf($dept);