<?php
include_once 'PHPRtfLite.php';

//if (!isset($argv[1]))
//    exit(1);

// ============================================ Данные полученные от модели ============================================

$par = json_decode($argv[1], true);
$wp_count = $par['workplace_count']; // Общие данные
$workplaces = $par['workplaces']; // Массив РМ

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

$section->writeText('<br>Перечень рабочих мест отдела ' . $wp_count['division'] . '<br>', $fontHeader, $headFormat);

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

for ($i = 1; $i < $rows; $i ++) {
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
    foreach ($workplaces[$i-1]['inv_items'] as $item) {
        array_push($invs, $item['invent_num']);
    }
    $list = $workplaces[$i-1]['workplace_type']['short_description'] . ' (инв. №№: ' . join(', ', $invs) . ')';

    $table->writeToCell($i + 1, 2, $list, $font);
    $table->writeToCell($i + 1, 3, $workplaces[$i-1]['user_iss']['fio_initials'], $font);
    $table->writeToCell($i + 1, 4, 'Пл. ' . $workplaces[$i-1]['iss_reference_site']['name'] . ', корп. ' . $workplaces[$i-1]['iss_reference_building']['name'] . ', комн. ' . $workplaces[$i-1]['iss_reference_room']['name'], $font);
}

// ============================================ Футер ==================================================================

$section->writeText('', $font, $tableFormat);

$table = $section->addTable();
$table->addRows(1, 0.7);
$table->addColumnsList(array(10.6, 7.3));

$cell = $table->getCell(1, 2);
$cell->setTextAlignment(PHPRtfLite_ParFormat::TEXT_ALIGN_RIGHT);

$table->writeToCell(1, 1, 'Руководитель подразделения ' . $wp_count['division'], $font);
$table->writeToCell(1, 2, '/________________/', $font);

$rtf->sendRtf($wp_count['division']);
