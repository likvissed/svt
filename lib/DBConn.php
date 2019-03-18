<?php

class DBConn{
  private $host;
  private $user;
  private $pass;

  private $dbh;
  private $error;
  private $stmt;

  public function __construct($data){
    $this->host = $data['host'];
    $this->user = $data['username'];
    $this->pass = $data['password'];

    $dsn = 'mysql:host='.$this->host.';dbname='.$data['database'];
    $options = array(
      PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    );
    try{
      $this->dbh = new PDO($dsn, $this->user, $this->pass, $options);
        $this->dbh->exec("set names utf8");
    }
    catch(PDOException $e){
      $this->error = $e->getMessage();
      echo 'Произошла ошибка при обращении к базе '.$data['database'].'<BR>';
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

  public function debug() {
    return $this->stmt->debugDumpParams();
  }  
}