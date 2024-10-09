<?php
include ('h.php');
$connection = mysqli_connect('localhost','root','','book_store');
if($connection){
    echo "we are connected";
}else{
 
    die("Database Connection Fail");
}

if(isset($_GET['submit'])){
 $cc_id = $_GET["cust_id"];
 echo $cc_id;
 $result1 = mysqli_query($connection, "CALL getCustAllOrder($cc_id)");
 if(!$result1){
    die('Query Failed'.mysqli_error($connection));
 }
 echo '<table class="table table-danger table-striped">';
echo "<tr>";
echo "<th> cust id </th>";
echo "<th> cust fname </th>";
echo "<th> cust lname </th>";
echo "<th> order id </th>";
echo "<th> total</th>";
echo "</tr>";
while($row1 = mysqli_fetch_array($result1)){
$cid = $row1['cust_id'];
$cfname = $row1['cust_fname'];
$clname = $row1['cust_lname'];
$corder = $row1['order_id'];
$ctotal =$row1['gtotal'];
echo "<tr>";
echo "<td>".$cid."</td>";
echo "<td>".$cfname."</td>";
echo "<td>".$clname."</td>";
echo "<td>".$corder."</td>";
echo "<td>".$ctotal."</td>";
echo "</tr>";
}
echo '</table>';
}
?>
<?php
     function showAllData(){
        global $connection;
        $query = "SELECT * from customer";
        $result = mysqli_query($connection,$query);
        if(!$result){
            die('Query Failed'. mysqli_error($connection));
        }
        while($row=mysqli_fetch_assoc($result)){
            $cust_id=$row['CUST_ID'];
            $cust_fname=$row['CUST_FNAME'];
            $cust_lname=$row['CUST_LNAME'];
            echo "<option value='$cust_id'>$cust_id"." "."$cust_fname"." "."$cust_lname</option>";
        }
    }
?>
<!DOCTYPE html>
<html>
<head>
<title> Book Store Database </title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</head>
<body>
    <form action="index.php" method ="get">
    <label for="fname">รหัสลูกค้า:</label><br>
  <select name="cust_id" cust_id="">
                  <option value="">-- Please Select Item --</option>
                  <?php
                  showAllData(); 
                   ?> 
                </select>
              <p>
              </p>
  <input type="submit" name="submit" value="Submit">    
        
    </form>
</body>
</html>
