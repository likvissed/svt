<?php
include_once 'PHPRtfLite.php';

//if (!isset($argv[1]))
//    exit(1);

// ============================================ Данные полученные от модели ============================================

//$par = json_decode($argv[1], true);
//$wp_count = $par['workplace_count']; // Общие данные
//$workplaces = $par['workplaces']; // Массив РМ
$dept = $argv[1];

$dbname = 'netadmin';

$con = new DBConn ('cosmos', $dbname);
$con->prepare_query('SELECT wi.workplace_id,u.fio_initials,iwt.short_description,irs.name AS site,irb.name as corp, irr.name FROM invent_workplace AS wi, invent_workplace_type as iwt, netadmin.user_iss AS u, netadmin.iss_reference_sites AS irs, netadmin.iss_reference_buildings AS irb, netadmin.iss_reference_rooms AS irr where u.id_tn=wi.id_tn AND irs.site_id=wi.location_site_id AND irb.building_id=wi.location_building_id AND irr.room_id=wi.location_room_id AND iwt.workplace_type_id=wi.workplace_type_id AND u.id_tn IN (SELECT id_tn FROM netadmin.user_iss WHERE dept=:dept) ORDER BY wi.workplace_id;');
$con->bind(':dept', $dept);
$workplaces = $con->row_set();
$wp_count = count($workplaces);

// ============================================ Инициализация страницы =================================================

PHPRtfLite::registerAutoloader();
$rtf = new PHPRtfLite(); //Основной класс
$rtf->setMargins(1.7, 0.8, 1, 1);

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

$table = $section->addTable();
$rows = 4;
$table->addRows($rows, 0.7);
$table->addColumnsList(array(10.6, 7.3));

for ($i = 1; $i <= $rows; $i ++) {
    $cell = $table->getCell($i, 2);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_RIGHT);
}


$table->writeToCell(1, 2, 'Начальнику УИВТ', $font);
$table->writeToCell(2, 2, 'И. В. Потуремскому', $font);
$table->writeToCell(3, 2, '__________________', $font);
$table->writeToCell(4, 2, '"___" ____________ 20___г.', $font);

$section->writeText('<br>Перечень рабочих мест отдела ' . $dept . '<br>', $fontHeader, $headFormat);
;
// ============================================ Контент ================================================================

$table = $section->addTable();
$rows = count($workplaces) + 1;
$cols = 4;
$height = 0.45; // Базовая высота ячейки
$mainBorder = new PHPRtfLite_Border_Format(1); //Формат барьера
$border = new PHPRtfLite_Border($rtf, $mainBorder, $mainBorder, $mainBorder, $mainBorder);

$table->addRows($rows, $height);
$table->addColumnsList(array(2, 9, 3.7, 3.2));
$table->setBorderForCellRange($border, 1, 1, $rows, $cols);

$table->setBackgroundForCellRange('#e0e0e0', 1, 1, 1, 4);

for ($i = 1; $i <= $cols; $i ++) {
    $cell = $table->getCell(1, $i);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
}

$table->writeToCell(1, 1, '№', $fontBold);
$table->writeToCell(1, 2, 'Описание', $fontBold);
$table->writeToCell(1, 3, 'Ответственный', $fontBold);
$table->writeToCell(1, 4, 'Расположение', $fontBold);

$i = 1;
foreach ($workplaces as $wp){
//for ($i = 1; $i < $rows; $i ++) {
    $cell = $table->getCell($i, 1);

    $cell = $table->getCell($i + 1, 1);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
    $cell->setVerticalAlignment('center');

    $cell = $table->getCell($i + 1, 2);
    $cell->setCellPaddings(0.2, 0.2, 0.2, 0.2);
    $cell->setVerticalAlignment('center');

    $cell = $table->getCell($i + 1, 3);
    $cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_CENTER);
    $cell->setVerticalAlignment('center');

    $cell = $table->getCell($i + 1, 4);
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

    $table->writeToCell($i + 1, 2, $list, $font);
    $table->writeToCell($i + 1, 3, $wp['fio_initials'], $font);
    $table->writeToCell($i + 1, 4, 'Пл. ' . $wp['site'] . ', корп. ' . $wp['corp'] . ', комн. ' . $wp['name'], $font);
    $i++;
}

// ============================================ Футер ==================================================================

$section->writeText('', $font, $tableFormat);

$table = $section->addTable();
$table->addRows(1, 0.7);
$table->addColumnsList(array(10.6, 7.3));

$cell = $table->getCell(1, 2);
$cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_RIGHT);

$table->writeToCell(1, 1, 'Руководитель подразделения ' . $dept, $font);
$table->writeToCell(1, 2, '/________________/', $font);

$rtf->sendRtf($dept);























class DBConn{
  private $host;
  private $user;
  private $pass;

  private $dbh;
  private $error;
  private $stmt;

  public function __construct($dbhost, $dbname){
    switch ($dbhost){
      case "cosmos":
                      #require_once 'cosmos_login.inc.php';
                      $this->host = 'sql***REMOVED***.npopm.ru';
                      $this->user = 'inv_prod';
                      $this->pass = 'yk%pzD{2lE1k}V7~';
                      break;
    }
      $dsn = 'mysql:host='.$this->host.';dbname='.$dbname;
    $options = array(
      PDO::ATTR_ERRMODE    => PDO::ERRMODE_EXCEPTION
    );
    try{
      $this->dbh = new PDO($dsn, $this->user, $this->pass, $options);
        $this->dbh->exec("set names utf8");
    }
    catch(PDOException $e){
      $this->error = $e->getMessage();
      echo 'Произошла ошибка при обращении к базе '.$dbname.'<BR>';
      echo $e->getMessage();
    }
  }

  public function prepare_query($query){

    $this->stmt = $this->dbh->prepare($query);
  }

  public function bind($param, $value, $type = null){
    if (is_null($type)) {
      switch (true) {
        case is_int($value):
          $type = PDO::PARAM_INT;
          break;
        case is_bool($value):
          $type = PDO::PARAM_BOOL;
          break;
        case is_null($value):
          $type = PDO::PARAM_NULL;
          break;
        default:
          $type = PDO::PARAM_STR;
      }
    }
    $this->stmt->bindValue($param, $value, $type);
  }

  public function execute(){
    return $this->stmt->execute();
  }

  public function row_set(){
    $this->execute();
    return $this->stmt->fetchAll(PDO::FETCH_ASSOC);
  }

  public function row_single(){
    $this->execute();
    return $this->stmt->fetch(PDO::FETCH_ASSOC);
  }

  public function row_count(){
    return $this->stmt->rowCount();
  }

  public function begin_transaction(){
    return $this->dbh->beginTransaction();
  }

  public function last_id(){
    $id = $this->dbh->lastInsertId();
    $this->dbh->commit();
    return $id;
  }

  public function commited(){
    return $this->dbh->commit();
  }

}