-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 09, 2024 at 04:51 PM
-- Server version: 10.4.25-MariaDB
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `book_store`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `getCustAllOrder` (IN `cid` INT(2))   BEGIN
select cust_id, cust_fname, cust_lname, order_id, sum(total) as gtotal from
(
select c.cust_id, c.cust_fname, c.cust_lname, od.order_id, b.price*od.qty as total
from customer c, saleorder s, order_detail od, book b
WHERE od.BOOK_ID=b.BOOK_ID
and od.ORDER_ID = s.ORDER_ID
and s.CUST_ID = c.CUST_ID
union all
select c.cust_id, c.cust_fname, c.cust_lname, od.order_id, p.pset_price*od.qty as total
from customer c, saleorder s, order_detail od, promo_set p
WHERE od.PSET_ID= p.PSET_ID
and od.ORDER_ID = s.ORDER_ID
and s.CUST_ID = c.CUST_ID
) as t1
group by cust_id, cust_fname, cust_lname, order_id
having cust_id = cid
order by order_id;   

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getCustomer` (IN `cid` INT)   BEGIN	
    DECLARE c_id INT;
    DECLARE c_fname VARCHAR(500);
    DECLARE c_lname VARCHAR(500);
    DECLARE c_tid INT;
    DECLARE end_record BOOLEAN DEFAULT FALSE;
    DECLARE cust_cursor CURSOR FOR 
        SELECT cust_id, cust_fname, cust_lname, cust_type_id
        FROM customer
        WHERE cust_type_id = cid;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET end_record = TRUE;

    CREATE TEMPORARY TABLE IF NOT EXISTS temp_customer (
        cust_id INT,
        cust_fname VARCHAR(500),
        cust_lname VARCHAR(500),
        cust_type_id INT
    );

    OPEN cust_cursor;
    cust_loop: LOOP
        FETCH cust_cursor INTO c_id, c_fname, c_lname, c_tid;
        IF end_record THEN
            LEAVE cust_loop;
        END IF;
        INSERT INTO temp_customer (cust_id, cust_fname, cust_lname, cust_type_id)
        VALUES (c_id, c_fname, c_lname, c_tid);
    END LOOP cust_loop;
    CLOSE cust_cursor;
    
    SELECT * FROM temp_customer;
    DROP TEMPORARY TABLE IF EXISTS temp_customer;
    
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `finddiscount` (`total` FLOAT) RETURNS FLOAT DETERMINISTIC BEGIN
    DECLARE discount FLOAT;
    
    IF total > 3000 THEN
        SET discount = (total * 20) / 100;
    ELSEIF total > 2000 THEN
        SET discount = (total * 15) / 100;
    ELSEIF total > 1000 THEN
        SET discount = (total * 10) / 100;
    ELSE
        SET discount = (total * 5) / 100;
    END IF;
    
    RETURN discount;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `book`
--

CREATE TABLE `book` (
  `BOOK_ID` int(11) NOT NULL,
  `BOOK_NAME` varchar(100) DEFAULT NULL,
  `PRICE` int(11) DEFAULT NULL,
  `BOOK_QTY` int(11) DEFAULT NULL,
  `BOOK_DESC` varchar(255) DEFAULT NULL,
  `BOOK_TYPEID` int(11) DEFAULT NULL,
  `PUBLISHER_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `book`
--

INSERT INTO `book` (`BOOK_ID`, `BOOK_NAME`, `PRICE`, `BOOK_QTY`, `BOOK_DESC`, `BOOK_TYPEID`, `PUBLISHER_ID`) VALUES
(1, 'king', 50, 7, 'good', 1, 1),
(2, 'queen', 8000, 10, 'bad', 2, 2),
(3, 'knight', 10, 2, 'so so', 3, 1),
(4, 'mouse', 700, 10, 'very good', 6, 3),
(5, 'goodboybadcat', 100, 2, 'gooddd', 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `CUST_ID` int(11) NOT NULL,
  `CUST_FNAME` varchar(50) DEFAULT NULL,
  `CUST_LNAME` varchar(50) DEFAULT NULL,
  `CUST_PHONE` varchar(20) DEFAULT NULL,
  `CUS_AGE` int(11) DEFAULT NULL,
  `CUST_TYPE_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`CUST_ID`, `CUST_FNAME`, `CUST_LNAME`, `CUST_PHONE`, `CUS_AGE`, `CUST_TYPE_ID`) VALUES
(1, 'john', 'rose', '987654321', 20, 1),
(2, 'jonhson', 'chawrai', '777', 50, 2),
(3, 'frank', 'frod', '111', 40, 3),
(4, 'snake', 'able', '123', 11, 2),
(5, 'sank', 'snake', '1111', 22, 2),
(6, 'sank', 'brother', '12345', 11, 1);

--
-- Triggers `customer`
--
DELIMITER $$
CREATE TRIGGER `checkAge` BEFORE INSERT ON `customer` FOR EACH ROW BEGIN
    -- Check if the customer's age exceeds 99
    IF NEW.CUS_AGE > 99 THEN 
        -- Raise an error if the age exceeds 99
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Age should not exceed 99!';
    ELSE 
        -- Insert the new data into the backup table if age is valid
        INSERT INTO customer_bkup 
        (
            CUST_ID, CUST_FNAME, CUST_LNAME, 
            CUST_TYPE_ID, CUS_AGE
        )
        VALUES
        (
            NEW.CUST_ID, NEW.CUST_FNAME, NEW.CUST_LNAME,
            NEW.CUST_TYPE_ID, NEW.CUS_AGE
        );
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `deleteCust` BEFORE DELETE ON `customer` FOR EACH ROW BEGIN
        DELETE FROM customer_bkup WHERE CUST_ID = OLD.CUST_ID;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `updateCust` BEFORE UPDATE ON `customer` FOR EACH ROW BEGIN
        UPDATE customer_bkup
        SET cust_fname = NEW.cust_fname , cust_lname = NEW.cust_lname , cust_type_id = NEW.cust_type_id , CUS_AGE = NEW.cus_age 
        where cust_id = OLD.cust_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `customer_bkup`
--

CREATE TABLE `customer_bkup` (
  `CUST_ID` int(11) NOT NULL,
  `CUST_FNAME` varchar(50) DEFAULT NULL,
  `CUST_LNAME` varchar(50) DEFAULT NULL,
  `CUST_PHONE` varchar(20) DEFAULT NULL,
  `CUS_AGE` int(11) DEFAULT NULL,
  `CUST_TYPE_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `customer_type`
--

CREATE TABLE `customer_type` (
  `CUST_TYPE_ID` int(11) NOT NULL,
  `CUST_TYPENAME` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `customer_type`
--

INSERT INTO `customer_type` (`CUST_TYPE_ID`, `CUST_TYPENAME`) VALUES
(1, 'new'),
(2, 'premium'),
(3, 'old');

-- --------------------------------------------------------

--
-- Table structure for table `order_detail`
--

CREATE TABLE `order_detail` (
  `ORDER_ID` int(11) NOT NULL,
  `SEQ` int(11) NOT NULL,
  `QTY` int(11) DEFAULT NULL,
  `BOOK_ID` int(11) DEFAULT NULL,
  `PSET_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `order_detail`
--

INSERT INTO `order_detail` (`ORDER_ID`, `SEQ`, `QTY`, `BOOK_ID`, `PSET_ID`) VALUES
(1, 1, 1, 2, NULL),
(1, 2, 2, 1, NULL),
(1, 3, 5, 4, NULL),
(2, 1, 3, 2, NULL),
(2, 2, 1, 3, NULL),
(3, 1, 2, 2, NULL),
(3, 2, 1, 3, NULL),
(4, 1, 10, 5, NULL),
(5, 1, 12, 4, NULL),
(6, 1, 20, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `promo_set`
--

CREATE TABLE `promo_set` (
  `PSET_ID` int(11) NOT NULL,
  `PSET_STDATE` date DEFAULT NULL,
  `PSET_ENDDATE` date DEFAULT NULL,
  `PSET_PRICE` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `promo_set`
--

INSERT INTO `promo_set` (`PSET_ID`, `PSET_STDATE`, `PSET_ENDDATE`, `PSET_PRICE`) VALUES
(1, '2000-01-01', '2000-02-01', 100),
(2, '2000-01-01', '2000-07-01', 200),
(3, '2050-07-05', '2055-05-07', 100000);

-- --------------------------------------------------------

--
-- Table structure for table `saleorder`
--

CREATE TABLE `saleorder` (
  `ORDER_ID` int(11) NOT NULL,
  `ORDER_DATE` date DEFAULT NULL,
  `ORDER_TOTAL` decimal(10,2) DEFAULT NULL,
  `CUST_ID` int(11) DEFAULT NULL,
  `SALE_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `saleorder`
--

INSERT INTO `saleorder` (`ORDER_ID`, `ORDER_DATE`, `ORDER_TOTAL`, `CUST_ID`, `SALE_ID`) VALUES
(1, '2000-01-01', '11600.00', 1, 1),
(2, '2222-01-01', '24010.00', 1, 2),
(3, '2006-02-01', '16010.00', 3, 2),
(4, '2001-11-01', '1000.00', 2, 1),
(5, '2003-01-01', '8400.00', 4, 2),
(6, '2001-05-02', '1000.00', 5, 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `book`
--
ALTER TABLE `book`
  ADD PRIMARY KEY (`BOOK_ID`);

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`CUST_ID`),
  ADD KEY `CUST_TYPE_ID` (`CUST_TYPE_ID`);

--
-- Indexes for table `customer_bkup`
--
ALTER TABLE `customer_bkup`
  ADD PRIMARY KEY (`CUST_ID`);

--
-- Indexes for table `customer_type`
--
ALTER TABLE `customer_type`
  ADD PRIMARY KEY (`CUST_TYPE_ID`);

--
-- Indexes for table `order_detail`
--
ALTER TABLE `order_detail`
  ADD PRIMARY KEY (`ORDER_ID`,`SEQ`);

--
-- Indexes for table `promo_set`
--
ALTER TABLE `promo_set`
  ADD PRIMARY KEY (`PSET_ID`);

--
-- Indexes for table `saleorder`
--
ALTER TABLE `saleorder`
  ADD PRIMARY KEY (`ORDER_ID`),
  ADD KEY `CUST_ID` (`CUST_ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `customer`
--
ALTER TABLE `customer`
  MODIFY `CUST_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2147483648;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `customer`
--
ALTER TABLE `customer`
  ADD CONSTRAINT `CUST_TYPE_ID` FOREIGN KEY (`CUST_TYPE_ID`) REFERENCES `customer_type` (`CUST_TYPE_ID`);

--
-- Constraints for table `order_detail`
--
ALTER TABLE `order_detail`
  ADD CONSTRAINT `order_detail_ibfk_1` FOREIGN KEY (`ORDER_ID`) REFERENCES `saleorder` (`ORDER_ID`);

--
-- Constraints for table `saleorder`
--
ALTER TABLE `saleorder`
  ADD CONSTRAINT `saleorder_ibfk_1` FOREIGN KEY (`CUST_ID`) REFERENCES `customer` (`CUST_ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
