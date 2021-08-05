<?php
include_once 'PHPRtfLite.php';
include_once 'DBConn.php';

// ============================================ Данные полученные от модели ============================================

$env = $argv[1] . '_invent';
$order_id = $argv[2];
$consumer = $argv[3];
$date = $argv[4];
$invent_params = json_decode($argv[5], true);
$warehouse_params = json_decode($argv[6], true);
$database = yaml_parse_file('config/database.yml');
$database[$env]['host'] = $_SERVER['MYSQL_NETADMIN_SLAVE'];
$token = $argv[7];
$employee_uri = $argv[8];

if ($_SERVER['RAILS_ENV'] === 'production') {
  $database[$env]['username'] = $_SERVER['MYSQL_PRODUCTION_USER'];
  $database[$env]['password'] = $_SERVER['MYSQL_PRODUCTION_PASSWORD'];
} else {
  $database[$env]['username'] = $_SERVER['MYSQL_DEV_USER'];
  $database[$env]['password'] = $_SERVER['MYSQL_DEV_PASSWORD'];
}

$con = new DBConn ($database[$env]);

if (!empty($invent_params)) {
  $query = "
  SELECT
    warehouse_orders.*, invent_item.*, warehouse_operations.item_model, invent_property_value.value as str_val, invent_property_list.short_description as list_val, property.short_description as property, invent_type.short_description as type, iss_reference_buildings.name as building, iss_reference_rooms.name as room, invent_workplace_count.division as division, invent_workplace.id_tn
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

  // print_r($query);
  // return;

  $i = 0;
  foreach($invent_params as $par) {
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
  LEFT OUTER JOIN
    (SELECT * FROM invent_property WHERE mandatory = TRUE) property
  ON
    property.property_id = invent_property_value.property_id
  LEFT OUTER JOIN
    invent_property_list
  ON
    invent_property_list.property_list_id = invent_property_value.property_list_id
  LEFT OUTER JOIN
    invent_workplace
  ON
    invent_workplace.workplace_id = warehouse_orders.invent_workplace_id
  LEFT OUTER JOIN
    netadmin.iss_reference_buildings
  ON
    netadmin.iss_reference_buildings.building_id = invent_workplace.location_building_id
  LEFT OUTER JOIN
    netadmin.iss_reference_rooms
  ON
    netadmin.iss_reference_rooms.room_id = invent_workplace.location_room_id
  LEFT OUTER JOIN
    invent_workplace_count
  ON
    invent_workplace_count.workplace_count_id = invent_workplace.workplace_count_id
  WHERE
    warehouse_orders.id = :order_id
  ORDER BY
    invent_item.item_id";

  $con->prepare_query($query);
  $con->bind(':order_id', $order_id);
  $i = 0;

  // print_r($con);
  // return;
  // // var_dump($con);
  // exit;

  foreach($invent_params as $par) {
    $con->bind(":item_id$i", $par['item_id']);
    $i++;
  }
  $sql_invent_data = $con->row_set();

  // print_r($sql_invent_data);
  // print_r($con->debug());
  // return;
}

if (!empty($warehouse_params)) {
  $query = "
  SELECT
    warehouse_orders.invent_num AS order_num, warehouse_orders.request_num, warehouse_operations.*, iss_reference_buildings.name as building, iss_reference_rooms.name as room, invent_workplace_count.division as division, invent_workplace.id_tn
  FROM
    warehouse_orders
  INNER JOIN
    warehouse_operations
  ON
    warehouse_operations.operationable_id = warehouse_orders.id AND warehouse_operations.id IN (";

  $i = 0;
  foreach($warehouse_params as $par) {
    $query .= ':op_id' . $i . ',';
    $i++;
  }
  $query = preg_replace('/,$/', '', $query);

  $query .= ')';
  $query .= "
  LEFT OUTER JOIN
    invent_workplace
  ON
    invent_workplace.workplace_id = warehouse_orders.invent_workplace_id
  LEFT OUTER JOIN
    netadmin.iss_reference_buildings
  ON
    netadmin.iss_reference_buildings.building_id = invent_workplace.location_building_id
  LEFT OUTER JOIN
    netadmin.iss_reference_rooms
  ON
    netadmin.iss_reference_rooms.room_id = invent_workplace.location_room_id
  LEFT OUTER JOIN
    invent_workplace_count
  ON
    invent_workplace_count.workplace_count_id = invent_workplace.workplace_count_id
  WHERE
    warehouse_orders.id = :order_id
  ";
  $con->prepare_query($query);
  $con->bind(':order_id', $order_id);
  $i = 0;
  foreach($warehouse_params as $par) {
    $con->bind(":op_id$i", $par);
    $i++;
  }
  $sql_warehouse_data = $con->row_set();

  // print_r($sql_warehouse_data);
  // return;
}


// Получаюший
$sql_consumer_data = get_emp_consumer($consumer);

// ===================================== Получение данных по tn или fio с НСИ ============================================

function get_emp_consumer($consumer)
{
  $url = $GLOBALS['employee_uri'] . "=fullName=='" . urlencode($consumer) . "',personnelNo==" . intval($consumer);
  $options = array(
    'http'=>array(
      'method'=>"GET",
      'header'=>'X-Auth-Token: '.$GLOBALS['token']
    )
  );

  $context  = stream_context_create($options);
  $response = file_get_contents($url, false, $context);

  if ($response) {
    $array_response = json_decode($response, true);
    if ($array_response['data']) {

      $arr = array();
      $arr['fio'] = get_fio($array_response['data'][0]['fullName']);
      $arr['tel'] = $array_response['data'][0]['phoneText'];
      
      return $arr;
    }
  }
}

// ======================================== Получение данных по id_tn с НСИ ==============================================

function get_employee($id_tn)
{
  $url     = $GLOBALS['employee_uri'] . '=id==' . $id_tn;
  $options = array(
    'http'=>array(
      'method'=>"GET",
      'header'=>'X-Auth-Token: '.$GLOBALS['token']
      
    )
  );

  $context  = stream_context_create($options);
  $response = file_get_contents($url, false, $context);

  if ($response) {
    $array_response = json_decode($response, true);
    if ($array_response['data']) {

      $arr = array();
      $arr['fio'] = get_fio($array_response['data'][0]['fullName']);
      $arr['tel'] = $array_response['data'][0]['phoneText'];
      
      return $arr;
    }
  }
}

// ============================================ Преобразование данных =================================================

$common_data = array();
$result = array();
$i = 0;
foreach($sql_invent_data as $row_data) {
  $index = get_result_index($row_data, $result);
  
  // Ответственный
  $responsible_wp_employee = get_employee($row_data['id_tn']);

  if (is_null($index)) {
    $index = $i;
    $result[$index] = array();
    $i++;
  }

  $result[$index]['warehouse_type'] = 'with_invent_num';
  $result[$index]['item_id'] = $row_data['item_id'];
  $result[$index]['request_num'] = $row_data['request_num'];
  $result[$index]['type'] = $row_data['type'];
  $result[$index]['item_model'] = $row_data['item_model'];
  $result[$index]['count'] = 1;

  if (!$common_data['building'])
    $common_data['building'] = $row_data['building'];
  if (!$common_data['room'])
    $common_data['room'] = $row_data['room'];
  if (!$common_data['division'])
    $common_data['division'] = $row_data['division'];
  if (!$common_data['tel'])
    $common_data['tel'] = $responsible_wp_employee['tel'];
  if (!$common_data['fio'])
    $common_data['fio'] = $responsible_wp_employee['fio'];
  if (!isset($result[$index]['invent_num'])) {
    foreach ($invent_params as $par) {
      if ($par['item_id'] == $result[$index]['item_id']) {
        $result[$index]['invent_num'] = $par['invent_num'] ? $par['invent_num'] : $row_data['invent_num'];
        $result[$index]['serial_num'] = $par['serial_num'] ? $par['serial_num'] : $row_data['serial_num'];
      }
    }
  }

  if (!isset($result[$index]['property_values'])) {
    $result[$index]['property_values'] = array();
  }

  array_push($result[$index]['property_values'], get_prop_val_object($row_data));
  // var_dump($result[$index]['property_values'] );

}
// exit;
foreach($sql_warehouse_data as $row_data) {
  $obj = array();
  $obj['warehouse_type'] = 'without_invent_num';
  $obj['request_num'] = $row_data['request_num'];
  $obj['order_num'] = $row_data['order_num'];
  $obj['item_type'] = $row_data['item_type'];
  $obj['item_model'] = $row_data['item_model'];
  $obj['count'] = abs($row_data['shift']);

  // Ответственный
  $responsible_wp_employee = get_employee($row_data['id_tn']);

  if (!$common_data['building'])
    $common_data['building'] = $row_data['building'];
  if (!$common_data['room'])
    $common_data['room'] = $row_data['room'];
  if (!$common_data['division'])
    $common_data['division'] = $row_data['division'];
  if (!$common_data['tel'])
    $common_data['tel'] = $responsible_wp_employee['tel'];
  if (!$common_data['fio'])
    $common_data['fio'] = $responsible_wp_employee['fio'];

  array_push($result, $obj);
}
//!!!
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

function get_fio($fioFull)
{
  $fioArr = explode(' ', $fioFull);
  $fio    = mb_substr($fioArr[1], 0, 1, 'utf-8') . '. ' . mb_substr($fioArr[2], 0, 1, 'utf-8') . '. ' . $fioArr[0];

  return $fio;
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

  if ($data['warehouse_type'] == 'with_invent_num') {
    $table->writeToCell($i + 1, 2, $data['type'], $fontBold);
    if ($data['type'] != 'Системный блок') {
      $table->writeToCell($i + 1, 2, ' ' . $data['item_model'], $fontBold);

    }
    $table->writeToCell($i + 1, 2, "\n", $fontBold);
    foreach($data['property_values'] as $prop_val) {

      if (isset($prop_val['property'])) {
        $table->writeToCell($i + 1, 2, $prop_val['property'] . ': ' . $prop_val['value'] . "\n", $table_font);
      }
    }
    $table->writeToCell($i + 1, 3, $data['count'], $table_font);

    // var_dump($sql_consumer_data[0]['fio']);
    // exit;

    $nested_table = $cell->addTable();
    $nested_table->addRows(4, 0.5);
    $nested_table->addColumnsList(array(6, 6));
    $nested_table->setBorderForCellRange($border, 1, 1, $rows, $cols);
    $nested_table->writeToCell(1, 1, ' ');
    $nested_table->writeToCell(1, 2, ' ');
    $nested_table->writeToCell(2, 1, ' ');
    $nested_table->writeToCell(2, 2, ' ');
    $nested_table->writeToCell(3, 1, 'Заявка № ' . $data['request_num'], $table_font);
    $nested_table->writeToCell(3, 2, 'Сер. № ' . $data['serial_num'], $table_font);
    $nested_table->writeToCell(4, 1, ' ');
    $nested_table->writeToCell(4, 2, 'Инв. № ' . $data['invent_num'], $table_font);
  } else if ($data['warehouse_type'] == 'without_invent_num') {
    $table->writeToCell($i + 1, 2, $data['item_type'] . ' ', $fontBold);
    $table->writeToCell($i + 1, 2, $data['item_model'] . ' ', $fontBold);

    $table->writeToCell($i + 1, 3, $data['count'], $table_font);

    $nested_table = $cell->addTable();
    $nested_table->addRows(4, 0.5);
    $nested_table->addColumnsList(array(6, 6));
    $nested_table->setBorderForCellRange($border, 1, 1, $rows, $cols);
    $nested_table->writeToCell(1, 1, ' ');
    $nested_table->writeToCell(1, 2, ' ');
    $nested_table->writeToCell(2, 1, ' ');
    $nested_table->writeToCell(2, 2, ' ');
    $nested_table->writeToCell(3, 1, 'Заявка № ' . $data['request_num'], $table_font);
    $nested_table->writeToCell(3, 2, 'Сер. № ' . $data['serial_num'], $table_font);
    $nested_table->writeToCell(4, 1, ' ');
    $nested_table->writeToCell(4, 2, 'Инв. № ' . $data['order_num'], $table_font);
  }

  $cell = $table->getCell($i + 1, 3);
  $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
  $cell->setVerticalAlignment(PHPRtfLite_Table_Cell::VERTICAL_ALIGN_CENTER);

  $i++;
}

$section->writeText('', $font, $tableFormat);

$table = $section->addTable();
$table->addRows(5, 1);
$table->addColumnsList(array(10.6, 7.3));

$cell = $table->getCell(1, 2);

// var_dump($common_data);
// exit;

$table->writeToCell(1, 1, 'Корпус ' . $common_data['building'], $footer_font);
$table->writeToCell(1, 2, 'Комната ' . $common_data['room'], $footer_font);
$table->writeToCell(2, 1, 'Подразделение ' . $common_data['division'], $footer_font);
$table->writeToCell(2, 2, 'Телефон ' . $common_data['tel'], $footer_font);
$table->writeToCell(3, 1, 'Ответственный: ' . $common_data['fio'], $footer_font);
$table->writeToCell(3, 2, 'Подпись  _____________________', $footer_font);
$table->writeToCell(4, 1, 'Получающий: ' . $sql_consumer_data['fio'], $footer_font);
$table->writeToCell(4, 2, 'Подпись  _____________________', $footer_font);
$table->writeToCell(5, 2, $date, $footer_font);
// $table->writeToCell(4, 2, '"_____" ________________ 20 г.', $footer_font);

$rtf->sendRtf($dept);