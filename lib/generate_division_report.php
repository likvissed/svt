<?php
include_once 'PHPRtfLite.php';
include_once 'DBConn.php';

//if (!isset($argv[1]))
//    exit(1);

// ============================================ Данные полученные от модели ============================================

//$par = json_decode($argv[1], true);
//$wp_count = $par['workplace_count']; // Общие данные
//$workplaces = $par['workplaces']; // Массив РМ

$env = $argv[1] . '_invent';
$dept = $argv[2];
$database = yaml_parse_file('config/database.yml');
$database[$env]['host'] = $_SERVER['MYSQL_NETADMIN_SLAVE'];
$token = $argv[3];
$employee_uri = $argv[4];

  // var_dump($employee_uri);
  // exit;

if ($_SERVER['RAILS_ENV'] === 'production') {
  $database[$env]['username'] = $_SERVER['MYSQL_PRODUCTION_USER'];
  $database[$env]['password'] = $_SERVER['MYSQL_PRODUCTION_PASSWORD'];
} elseif ($_SERVER['RAILS_ENV'] === 'staging') {
  $database[$env]['username'] = $_SERVER['MYSQL_STAGING_USER'];
  $database[$env]['password'] = $_SERVER['MYSQL_STAGING_PASSWORD'];
} else {
  $database[$env]['username'] = $_SERVER['MYSQL_DEV_USER'];
  $database[$env]['password'] = $_SERVER['MYSQL_DEV_PASSWORD'];
}

$con = new DBConn ($database[$env]);
$con->prepare_query('SELECT
                       WI.workplace_id,
                       WI.id_tn,
                       IWT.short_description,
                       IRS.name AS site,
                       IRB.name as corp,
                       IRR.name 
                     FROM 
                       invent_workplace AS WI
                     INNER JOIN (select * from invent_workplace_count where division = :dept) WC ON WC.workplace_count_id = WI.workplace_count_id 
                     INNER JOIN (select * from invent_workplace_type) IWT ON IWT.workplace_type_id = WI.workplace_type_id
                        
                     INNER JOIN (select * from netadmin.iss_reference_sites) IRS ON IRS.site_id = WI.location_site_id
                     INNER JOIN (select * from netadmin.iss_reference_buildings) IRB ON IRB.building_id = WI.location_building_id
                     INNER JOIN (select * from netadmin.iss_reference_rooms) IRR ON IRR.room_id = WI.location_room_id

                     ORDER BY WI.workplace_id;
                   ');

$con->bind(':dept', $dept);
$workplaces = $con->row_set();
$wp_count = count($workplaces);

// ======================================== Получение фамилии по id_tn с НСИ ============================================

function get_fio($id_tn)
{
  $user_not_found = 'Ответственный не найден';

  if (is_null($id_tn)) {
    return $user_not_found;
  }

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

      $fioFull = $array_response['data'][0]['fullName'];
      $fioArr  = explode(' ', $fioFull);
      $fio     = $fioArr[0] . ' ' . mb_substr($fioArr[1], 0, 1, 'utf-8') . '. ' . mb_substr($fioArr[2], 0, 1, 'utf-8') . '.';

      return $fio;
    }
    return $user_not_found;
  }
}
// ============================================ Инициализация страницы =================================================

PHPRtfLite::registerAutoloader();
$rtf = new PHPRtfLite(); //Основной класс
$rtf->setMargins(1.2, 0.8, 1, 1);

$font = new PHPRtfLite_Font(12, 'Times New Roman'); //Шрифт
$fontError = new PHPRtfLite_Font(12, 'Times New Roman', null, '#e2c818'); //Шрифт для выделения недочетов в футере
$fontBold = new PHPRtfLite_Font(12, 'Times New Roman'); //Жирный шрифт
$fontBold->setBold();

$normalFormat = new PHPRtfLite_ParFormat('justify'); //Обычный абзац
$normalFormat->setIndentFirstLine(1);

$tableFormat = new PHPRtfLite_ParFormat(); //Таблица в шапке
$tableFormat->setIndentFirstLine(0);
$tableFormat->setSpaceAfter(8);

$headFormat = new PHPRtfLite_ParFormat('center'); //Заголовок
$fontHeader = new PHPRtfLite_Font(14, 'Times New Roman');

$section = $rtf->addSection();

// ============================================ Шапка ==================================================================

// $table = $section->addTable();
// $rows = 4;
// $table->addRows($rows, 0.7);
// $table->addColumnsList(array(10.6, 7.3));

// for ($i = 1; $i <= $rows; $i ++) {
//     $cell = $table->getCell($i, 2);
//     $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_RIGHT);
// }

// $table->writeToCell(1, 2, 'Начальнику УИВТ', $font);
// $table->writeToCell(2, 2, 'И. В. Потуремскому', $font);
// $table->writeToCell(3, 2, '__________________', $font);
// $table->writeToCell(4, 2, '"___" ____________ 20___г.', $font);

$section->writeText('<br>Перечень рабочих мест отдела ' . $dept . '<br>', $fontHeader, $headFormat);

// ============================================ Контент ================================================================

$table = $section->addTable();
$rows = count($workplaces) + 1;
$cols = 5;
$height = 0.45; // Базовая высота ячейки
$mainBorder = new PHPRtfLite_Border_Format(1); //Формат барьера
$border = new PHPRtfLite_Border($rtf, $mainBorder, $mainBorder, $mainBorder, $mainBorder);

$table->addRows($rows, $height);
$table->addColumnsList(array(1.3, 1.7, 9, 3.7, 3.2));
$table->setBorderForCellRange($border, 1, 1, $rows, $cols);

$table->setBackgroundForCellRange('#e0e0e0', 1, 1, 1, 4);

for ($i = 1; $i <= $cols; $i ++) {
    $cell = $table->getCell(1, $i);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
}

$table->writeToCell(1, 1, '№', $fontBold);
$table->writeToCell(1, 2, 'ID РМ', $fontBold);
$table->writeToCell(1, 3, 'Описание', $fontBold);
$table->writeToCell(1, 4, 'Ответственный', $fontBold);
$table->writeToCell(1, 5, 'Расположение', $fontBold);

$i = 1;
foreach ($workplaces as $wp){
//for ($i = 1; $i < $rows; $i ++) {
    $cell = $table->getCell($i, 1);

    $cell = $table->getCell($i + 1, 1);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
    $cell->setVerticalAlignment('center');

    $cell = $table->getCell($i + 1, 2);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
    $cell->setVerticalAlignment('center');

    $cell = $table->getCell($i + 1, 3);
    $cell->setCellPaddings(0.2, 0.2, 0.2, 0.2);
    $cell->setVerticalAlignment('center');

    $cell = $table->getCell($i + 1, 4);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
    $cell->setVerticalAlignment('center');

    $cell = $table->getCell($i + 1, 5);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
    $cell->setVerticalAlignment('center');
//    $cell->setTextAlignment(PHPRtfLite_Container::VERTICAL_ALIGN_CENTER);

    $table->writeToCell($i + 1, 1, $i, $font);

    $invs = [];
    /*foreach ($workplaces[$i-1]['inv_items'] as $item) {
        array_push($invs, $item['invent_num']);
    }*/
    $con->prepare_query('SELECT invent_num FROM invent_item WHERE workplace_id=:wp_id');
    $con->bind(':wp_id',$wp['workplace_id']);
    $invs_mass = $con->row_set();
    foreach($invs_mass as $inv)
      array_push($invs, $inv['invent_num']);
    $list = $wp['short_description'] . ' (инв. №№: ' . join(', ', $invs) . ')';

    $table->writeToCell($i + 1, 2, $wp['workplace_id'], $font);
    $table->writeToCell($i + 1, 3, $list, $font);
    $table->writeToCell($i + 1, 4, get_fio($wp['id_tn']), $font);
    $table->writeToCell($i + 1, 5, 'Пл. ' . $wp['site'] . ', корп. ' . $wp['corp'] . ', комн. ' . $wp['name'], $font);
    $i++;
}

// ============================================ Футер ==================================================================

// $section->writeText('', $font, $tableFormat);

// $table = $section->addTable();
// $table->addRows(1, 0.7);
// $table->addColumnsList(array(10.6, 7.3));

// $cell = $table->getCell(1, 2);
// $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_RIGHT);

// $table->writeToCell(1, 1, 'Руководитель подразделения ' . $dept, $font);
// $table->writeToCell(1, 2, '/________________/', $font);

$rtf->sendRtf($dept);
