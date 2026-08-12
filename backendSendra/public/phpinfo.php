<?php phpinfo();

$dsn = 'mysql:host=127.0.0.1;dbname=sendra';
$username = 'root';
$password = '123456';

try {
    $pdo = new PDO($dsn, $username, $password);
    echo "Connection successful!";
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}


?>

