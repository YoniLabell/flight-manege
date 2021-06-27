-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 24, 2020 at 05:24 PM
-- Server version: 10.4.11-MariaDB
-- PHP Version: 7.2.31

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `flight management`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `all_flights_byCompanyName_byDate` ()  NO SQL
    COMMENT 'All flights are sorted by company name, departure time. And show'
SELECT planes.company_Name, flights.departure_time, TIMEDIFF(flights.landing_time,flights.departure_time) AS Flight_Time, flights.origin, flights.target
FROM flights NATURAL JOIN planes
GROUP BY planes.company_Name, flights.departure_time, flights.origin, flights.target$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `all_flights_by_id` (IN `id` VARCHAR(20))  NO SQL
SELECT o.date_of_purchase, a1.country AS country_s, a1.airports_name AS airport_s, a2.country AS country_t, a2.airports_name AS airport_t, o.price
FROM orders o NATURAL JOIN tickets t NATURAL JOIN flights f JOIN airports a1 JOIN airports a2
WHERE o.id_customer = id AND f.origin = a1.airports_id AND f.target = a2.airports_id$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `biggest_flights_company` ()  NO SQL
    COMMENT 'Returns the name of the company (s) flying a plane with the most'
SELECT company_Name 
FROM planes NATURAL JOIN flights
WHERE num_of_seats IN ( SELECT MAX(num_of_seats) 
                       FROM planes NATURAL JOIN flights)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllFlightPerAirportAndDateByTime` (IN `aid` INT(10), IN `d` DATE)  SELECT departure_time, airports_name AS airport, country
FROM airports NATURAL JOIN
(
SELECT departure_time , destinaiton AS airports_id
FROM airports NATURAL JOIN
(
    SELECT flights.origin AS airports_id ,flights.departure_time As departure_time,flights.target AS destinaiton
    FROM flights
    WHERE d=flights.departure_time 
)F
WHERE airports_id =aid
)A$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllpeopleNameLandingByDate` (IN `d` DATE)  NO SQL
select A.country,A.airports_name, tickets.last_name_passenger,tickets.first_name_passenger
FROM tickets NATURAL JOIN (SELECT flights_id, airports.country AS country, airports.airports_name AS airports_name
				FROM flights JOIN airports
				WHERE flights.target = airports.airports_id AND flights.landing_time = d)A
GROUP BY country,  airports_name, tickets.last_name_passenger,tickets.first_name_passenger$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAvgTicketsPerDayForEachAirport` ()  SELECT country,airports_name,avg_num_of_tickest_per_day
FROM airports NATURAL JOIN
(
SELECT origin AS airports_id,AVG(number_of_tickets) AS avg_num_of_tickest_per_day
FROM
(
SELECT departure_time,flights.origin,SUM(T.number_of_tickests) AS number_of_tickets
FROM flights NATURAL JOIN
(
    SELECT tickets.flights_id AS flights_id,COUNT(*) AS number_of_tickests 
	FROM tickets 
	GROUP BY flights_id
)T
GROUP BY flights.departure_time,flights.origin
)F
GROUP BY origin
)A
ORDER BY avg_num_of_tickest_per_day DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getConnections` ()  SELECT F.day AS date,
A.country1 AS source_country,A.name1 AS source_airport,
A.country2 AS connection_country,A.name2 AS connection_airport,
A.country3 AS destination_country,A.name3 AS destination_airport,
F.time1 AS first_filght_time,F.time2 AS second_filght_time
FROM( 
   		 SELECT 
   		 A1.airports_id as id1,A1.country AS country1,A1.airports_name AS name1, 
    	 A2.airports_id as id2,A2.country AS country2,A2.airports_name AS name2, 
   		 A3.airports_id as id3,A3.country AS country3,A3.airports_name AS name3 
    	 FROM airports A1 JOIN airports A2 JOIN airports A3 )A, 
    (
         SELECT F1.origin AS src,F1.target AS con,F2.target AS dest, F1.departure_time AS day,
         F1.departure_time AS time1,F2.departure_time AS time2  
         FROM flights F1 JOIN flights F2 
         WHERE F1.target=F2.origin AND F1.departure_time=F2.departure_time AND F1.origin<>F2.target)F
WHERE A.id1=F.src AND A.id2=F.con AND A.id3=F.dest$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListOfFlightBackByTicketsAndDays` (IN `tid` INT(10), IN `d` INT)  SELECT F1.departure_time,
A1.country AS source_country,A1.airports_name AS source_airport,
A2.country AS destination_country,A1.airports_name AS destination_airport
FROM airports A1,airports A2,
(
SELECT  flights.origin AS origin ,flights.target AS target ,flights.departure_time AS departure_time
FROM flights,
(
    SELECT flights.departure_time AS departure_time,flights.origin AS origin,flights.target AS target
	FROM flights NATURAL JOIN
	(
		SELECT tickets.flights_id AS flights_id
		FROM tickets
		WHERE tickets.tickets_id=tid
	)T
)F
WHERE F.origin=flights.target AND F.target=flights.origin AND flights.departure_time>=F.departure_time+d
)F1		
WHERE F1.origin=A1.airports_id AND F1.target=A2.airports_id$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getNumberOfTicketsByDate` (IN `D` DATE)  SELECT departure_time AS date ,SUM(T.number_of_tickests) AS number_of_tickets
FROM flights NATURAL JOIN
(
    SELECT tickets.flights_id AS flights_id,COUNT(*) AS number_of_tickests 
	FROM tickets 
	GROUP BY flights_id
)T
GROUP BY flights.departure_time
HAVING departure_time=D$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getNumOfAvailableSeatsPerFlight` ()  SELECT flight_number,planes.num_of_seats-number_of_tickests AS number_of_available_seats
FROM planes NATURAL JOIN
(
SELECT flights.flights_id AS flight_number,flights.planes_id AS planes_id ,T.number_of_tickests AS number_of_tickests
FROM flights NATURAL JOIN
(
    SELECT flights_id ,COUNT(*) AS number_of_tickests 
	FROM tickets 
	GROUP BY tickets.flights_id
)T
)F$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getNumOfTickestFromMembersOrdersByDepartment` (IN `X` VARCHAR(30))  SELECT orders_id,count(*) AS number_of_economy 
FROM tickets T NATURAL JOIN 
(
    SELECT O.orders_id AS orders_id
    FROM orders O NATURAL JOIN 
(
        SELECT club_members.club_members_id AS club_members_id
        FROM club_members 
 )C 
)N 
GROUP BY orders_id,department 
HAVING department=X$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `landing_in_X` (IN `countryName` VARCHAR(20))  NO SQL
    COMMENT 'The procedure gets "Country Name", And returns all flights that '
SELECT f.flights_id, p.company_Name, f.departure_time, a2.country, a2.airports_name
FROM flights f NATURAL JOIN planes p JOIN airports a1 JOIN airports a2
WHERE a1.airports_name = countryName AND f.target = a1.airports_id And a2.airports_id = f.origin$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `numOfPassengerComingIn` ()  NO SQL
SELECT a.country, a.airports_name, num_of_passenger
FROM airports a NATURAL JOIN (
    SELECT f.target AS airports_id, COUNT(DISTINCT t.id_passenger) AS num_of_passenger
    FROM tickets t NATURAL JOIN flights f 
    GROUP BY f.target)T$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `numOfPassengerLeavingFrom` ()  NO SQL
SELECT a.country, a.airports_name, num_of_passenger
FROM airports a NATURAL JOIN (
    SELECT f.origin AS airports_id, COUNT(DISTINCT t.id_passenger) AS num_of_passenger
    FROM tickets t NATURAL JOIN flights f 
    GROUP BY f.origin)T$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Origin_from_X` (IN `airportName` VARCHAR(20))  NO SQL
    DETERMINISTIC
    COMMENT 'The procedure gets "Country Name", And returns all flights depar'
SELECT f.flights_id, p.company_Name, f.landing_time, a2.country, a2.airports_name
FROM flights f NATURAL JOIN planes p JOIN airports a1 JOIN airports a2
WHERE f.origin = a1.airports_id AND a1.country = airportName And f.target = a2.airports_id$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `percentage_of_company_name_from flight` ()  NO SQL
SELECT company_Name,(ci/co)*100 as percentage 
FROM (  SELECT COUNT(*) as ci,company_Name
    FROM flights NATURAL join planes
    GROUP BY company_Name)f
        JOIN
        (SELECT COUNT(*) as co
        FROM flights)t$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pilot_longest_flight` ()  NO SQL
    COMMENT 'The pilot who flies the longest flight'
SELECT pilots.name, MAX(TIMEDIFF(flights.landing_time,flights.departure_time)) AS Flight_Time
FROM flights NATURAL JOIN pilots$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `airports`
--

CREATE TABLE `airports` (
  `airports_id` int(10) NOT NULL,
  `city` varchar(20) NOT NULL,
  `country` varchar(20) NOT NULL,
  `type` enum('military','private','public') NOT NULL,
  `airports_name` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `airports`
--

INSERT INTO `airports` (`airports_id`, `city`, `country`, `type`, `airports_name`) VALUES
(4, 'BEIJING', 'CHINA', 'public', 'BEIJING_CAPITAL_AIRP'),
(5, 'TEL_AVIV', 'ISRAEL', 'public', 'BEN_GURION_AIRPORT'),
(6, 'ALBERTA', 'CANADA', 'public', 'EDMONTON_INT_AIRPORT'),
(7, 'SEATTLE', 'WASHINGTON_USA', 'public', 'SEATTLE_TACOMA_INT_A'),
(8, 'AMMAN', 'JORDAN', 'public', 'QUEEN_ALIA_INT_AIRPO');

-- --------------------------------------------------------

--
-- Table structure for table `club_members`
--

CREATE TABLE `club_members` (
  `club_members_id` int(10) NOT NULL,
  `credit_points` int(10) NOT NULL,
  `status` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_members`
--

INSERT INTO `club_members` (`club_members_id`, `credit_points`, `status`) VALUES
(1, 59, 'SILVER'),
(2, 100, 'GOLD'),
(3, 91, 'PLATINUM'),
(4, 21, 'SILVER'),
(5, 51, 'GOLD'),
(6, 0, 'GOLD'),
(7, 50, 'SILVER'),
(8, 100, 'PLATINUM'),
(9, 150, 'GOLD'),
(10, 200, 'SILVER'),
(11, 250, 'PLATINUM'),
(12, 300, 'GOLD'),
(13, 350, 'SILVER'),
(14, 400, 'PLATINUM'),
(15, 450, 'GOLD');

-- --------------------------------------------------------

--
-- Table structure for table `flights`
--

CREATE TABLE `flights` (
  `flights_id` int(10) NOT NULL,
  `planes_id` int(10) NOT NULL,
  `pilots_id` int(10) NOT NULL,
  `departure_time` date NOT NULL,
  `landing_time` date NOT NULL,
  `origin` int(10) NOT NULL,
  `target` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `flights`
--

INSERT INTO `flights` (`flights_id`, `planes_id`, `pilots_id`, `departure_time`, `landing_time`, `origin`, `target`) VALUES
(1, 1, 1, '2020-04-12', '2020-04-12', 4, 5),
(2, 1, 1, '2020-04-21', '2020-04-21', 5, 6),
(3, 4, 3, '2020-04-05', '2020-04-06', 7, 8),
(4, 3, 2, '2020-04-14', '2020-04-14', 8, 4),
(5, 6, 2, '2020-05-18', '2020-05-18', 6, 7),
(6, 28, 8, '2020-06-01', '2020-06-03', 8, 4),
(10, 41, 7, '2020-06-01', '2020-06-02', 4, 5),
(11, 42, 19, '2020-06-02', '2020-06-03', 5, 6),
(16, 40, 15, '2020-06-01', '2020-06-02', 5, 7),
(17, 34, 17, '2020-06-02', '2020-06-03', 8, 4),
(18, 33, 22, '2020-06-03', '2020-06-04', 7, 6),
(19, 34, 21, '2020-06-04', '2020-06-05', 6, 5),
(21, 39, 4, '2020-06-01', '2020-06-02', 5, 6),
(24, 28, 11, '2020-06-02', '2020-06-03', 5, 7),
(25, 38, 2, '2020-06-03', '2020-06-04', 6, 5),
(26, 34, 4, '2020-06-04', '2020-06-05', 7, 8),
(27, 41, 1, '2020-06-05', '2020-06-06', 8, 6),
(29, 30, 11, '2020-06-07', '2020-06-08', 5, 7),
(30, 28, 11, '2020-06-08', '2020-06-09', 6, 5),
(31, 31, 15, '2020-06-09', '2020-06-10', 7, 8),
(32, 41, 10, '2020-06-10', '2020-06-11', 8, 6),
(34, 38, 10, '2020-06-12', '2020-06-13', 5, 7),
(35, 36, 19, '2020-06-13', '2020-06-14', 6, 5),
(36, 42, 6, '2020-06-14', '2020-06-15', 7, 8),
(37, 39, 20, '2020-06-15', '2020-06-16', 8, 6),
(38, 28, 10, '2020-06-16', '2020-06-17', 4, 4),
(39, 31, 3, '2020-06-17', '2020-06-18', 5, 7),
(40, 45, 11, '2020-06-18', '2020-06-19', 6, 5),
(41, 29, 11, '2020-06-19', '2020-06-20', 7, 8),
(42, 41, 16, '2020-06-20', '2020-06-21', 8, 6);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `orders_id` int(10) NOT NULL,
  `club_members_id` int(10) DEFAULT NULL,
  `id_customer` varchar(20) NOT NULL,
  `first_name_customer` varchar(20) NOT NULL,
  `last_name_customer` varchar(20) NOT NULL,
  `price` int(10) NOT NULL,
  `paying_method` varchar(20) NOT NULL,
  `date_of_purchase` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`orders_id`, `club_members_id`, `id_customer`, `first_name_customer`, `last_name_customer`, `price`, `paying_method`, `date_of_purchase`) VALUES
(1, 1, '289467382', 'IDO', 'ASHUAL', 5049, 'VISA', '2020-04-30'),
(2, NULL, '123486102', 'MOSHE', 'COHEN', 2000, 'CREDIT', '2020-04-29'),
(3, 2, '235409856', 'DAN', 'LEVI', 1010, 'CREDIT_POINTS', '2020-04-30'),
(4, NULL, '347634909', 'SHIR', 'PEREZ', 10230, 'VISA', '2020-04-15'),
(5, NULL, '126549385', 'JACOB', 'LEVI', 5012, 'CREDIT', '2020-04-08'),
(6, 15, '5', 'yoni', 'labell', 700, 'VISA', '2020-06-24'),
(7, 14, '0', 'yoni0', 'labell0', 1728, 'VISA', '0000-00-00'),
(8, 14, '1', 'yoni1', 'labell1', 167, 'CREDIT', '2020-05-01'),
(9, 4, '2', 'yoni2', 'labell2', 1475, 'CREDIT_POINTS', '2020-06-02'),
(10, 4, '3', 'yoni3', 'labell3', 1449, 'VISA', '2020-04-03'),
(11, 6, '4', 'yoni4', 'labell4', 631, 'CREDIT', '2020-05-04'),
(12, 3, '5', 'yoni5', 'labell5', 1358, 'CREDIT_POINTS', '2020-06-05'),
(13, 14, '6', 'yoni6', 'labell6', 1293, 'VISA', '2020-04-06'),
(14, 6, '7', 'yoni7', 'labell7', 1094, 'CREDIT', '2020-05-07'),
(15, 11, '8', 'yoni8', 'labell8', 1681, 'CREDIT_POINTS', '2020-06-08'),
(16, 14, '9', 'yoni9', 'labell9', 1361, 'VISA', '2020-04-09'),
(17, 9, '10', 'yoni10', 'labell10', 722, 'CREDIT', '2020-05-10'),
(18, 9, '11', 'yoni11', 'labell11', 1926, 'CREDIT_POINTS', '2020-06-11'),
(19, 1, '12', 'yoni12', 'labell12', 919, 'VISA', '2020-04-12'),
(20, 4, '13', 'yoni13', 'labell13', 646, 'CREDIT', '2020-05-13'),
(21, 9, '14', 'yoni14', 'labell14', 1004, 'CREDIT_POINTS', '2020-06-14'),
(22, 9, '15', 'yoni15', 'labell15', 903, 'VISA', '2020-04-15'),
(23, 1, '16', 'yoni16', 'labell16', 1415, 'CREDIT', '2020-05-16'),
(24, 8, '17', 'yoni17', 'labell17', 1666, 'CREDIT_POINTS', '2020-06-17'),
(25, 5, '18', 'yoni18', 'labell18', 441, 'VISA', '2020-04-18'),
(26, 14, '19', 'yoni19', 'labell19', 1039, 'CREDIT', '2020-05-19');

-- --------------------------------------------------------

--
-- Table structure for table `pilots`
--

CREATE TABLE `pilots` (
  `pilots_id` int(10) NOT NULL,
  `name` varchar(20) NOT NULL,
  `Seniority` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `pilots`
--

INSERT INTO `pilots` (`pilots_id`, `name`, `Seniority`) VALUES
(1, 'avi', 4),
(2, 'moshe', 49),
(3, 'yoni', 7),
(4, 'dani0', 1),
(5, 'dani1', 2),
(6, 'dani2', 3),
(7, 'dani3', 4),
(8, 'dani4', 5),
(9, 'dani5', 6),
(10, 'dani6', 7),
(11, 'dani7', 8),
(12, 'dani8', 9),
(13, 'dani9', 10),
(14, 'dani10', 11),
(15, 'dani11', 12),
(16, 'dani12', 13),
(17, 'dani13', 14),
(18, 'dani14', 15),
(19, 'dani15', 16),
(20, 'dani16', 17),
(21, 'dani17', 18),
(22, 'dani18', 19),
(23, 'dani19', 20);

-- --------------------------------------------------------

--
-- Table structure for table `planes`
--

CREATE TABLE `planes` (
  `planes_id` int(10) NOT NULL,
  `company_Name` varchar(20) NOT NULL,
  `num_of_seats` int(4) NOT NULL,
  `date_of_production` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `planes`
--

INSERT INTO `planes` (`planes_id`, `company_Name`, `num_of_seats`, `date_of_production`) VALUES
(1, 'el-al', 500, '2020-04-01'),
(2, 'el-al', 750, '2019-09-11'),
(3, 'ista', 750, '2019-02-12'),
(4, 'ista', 500, '2020-04-09'),
(5, 'ista', 750, '2019-02-19'),
(6, 'ista', 550, '2017-04-09'),
(7, 'el-al', 890, '2020-06-02'),
(28, 'eireruop', 500, '0000-00-00'),
(29, 'wizz', 550, '2020-06-01'),
(30, 'AirFrance', 600, '2020-06-02'),
(31, 'eireruop', 650, '2020-06-03'),
(32, 'wizz', 700, '2020-06-04'),
(33, 'AirFrance', 750, '2020-06-05'),
(34, 'eireruop', 800, '2020-06-06'),
(35, 'wizz', 850, '2020-06-07'),
(36, 'AirFrance', 900, '2020-06-08'),
(37, 'eireruop', 950, '2020-06-09'),
(38, 'wizz', 1000, '2020-06-10'),
(39, 'AirFrance', 1050, '2020-06-11'),
(40, 'eireruop', 1100, '2020-06-12'),
(41, 'wizz', 1150, '2020-06-13'),
(42, 'AirFrance', 1200, '2020-06-14'),
(43, 'eireruop', 1250, '2020-06-15'),
(44, 'wizz', 1300, '2020-06-16'),
(45, 'AirFrance', 1350, '2020-06-17'),
(46, 'eireruop', 1400, '2020-06-18'),
(47, 'wizz', 1450, '2020-06-19');

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `tickets_id` int(10) NOT NULL,
  `orders_id` int(10) NOT NULL,
  `flights_id` int(10) NOT NULL,
  `first_name_passenger` varchar(20) NOT NULL,
  `last_name_passenger` varchar(20) NOT NULL,
  `id_passenger` varchar(20) NOT NULL,
  `line` int(10) NOT NULL,
  `chair` varchar(20) NOT NULL,
  `department` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tickets`
--

INSERT INTO `tickets` (`tickets_id`, `orders_id`, `flights_id`, `first_name_passenger`, `last_name_passenger`, `id_passenger`, `line`, `chair`, `department`) VALUES
(1, 1, 1, 'KOBE', 'COHEN', '903039302', 10, 'B', 'FIRST'),
(2, 1, 2, 'GIL', 'LEVI', '654347394', 13, 'C', 'ECONOMY'),
(3, 1, 3, 'JACOB', 'ASHUAL', '534672383', 13, 'A', 'ECONOMY'),
(4, 3, 4, 'SOL', 'LEVI', '758945489', 13, 'D', 'FIRST'),
(5, 3, 5, 'GAL', 'COHEN', '489403849', 2, 'F', 'FIRST'),
(6, 2, 4, 'DAN', 'PEREZ', '789540499', 15, 'B', 'BUSINESS'),
(7, 7, 1, 'moshe', 'rapaport', '8920437', 23, 'A', 'BUSINESS'),
(8, 5, 36, 'moshe0', 'rapaport0', '0', 0, 'A', 'FIRST'),
(9, 2, 31, 'moshe1', 'rapaport1', '9999', 1, 'B', 'BUSINESS'),
(10, 10, 30, 'moshe2', 'rapaport2', '19998', 2, 'C', 'ECONOMY'),
(11, 4, 27, 'moshe3', 'rapaport3', '29997', 3, 'D', 'FIRST'),
(12, 10, 34, 'moshe4', 'rapaport4', '39996', 4, 'E', 'BUSINESS'),
(14, 14, 36, 'moshe0', 'rapaport0', '0', 0, 'A', 'FIRST'),
(16, 9, 1, 'moshe0', 'rapaport0', '0', 0, 'A', 'FIRST'),
(17, 18, 10, 'moshe1', 'rapaport1', '9999', 1, 'B', 'BUSINESS'),
(18, 2, 19, 'moshe2', 'rapaport2', '19998', 2, 'C', 'ECONOMY'),
(19, 17, 17, 'moshe3', 'rapaport3', '29997', 3, 'D', 'FIRST'),
(20, 24, 2, 'moshe4', 'rapaport4', '39996', 4, 'E', 'BUSINESS'),
(21, 20, 21, 'moshe5', 'rapaport5', '49995', 5, 'F', 'ECONOMY'),
(22, 8, 21, 'moshe6', 'rapaport6', '59994', 6, 'A', 'FIRST'),
(23, 21, 36, 'moshe7', 'rapaport7', '69993', 7, 'B', 'BUSINESS'),
(24, 6, 10, 'moshe8', 'rapaport8', '79992', 8, 'C', 'ECONOMY'),
(25, 13, 30, 'moshe9', 'rapaport9', '89991', 9, 'D', 'FIRST'),
(26, 23, 21, 'moshe0', 'rapaport0', '0', 0, 'A', 'FIRST'),
(27, 18, 21, 'moshe1', 'rapaport1', '9999', 1, 'B', 'BUSINESS'),
(28, 16, 10, 'moshe2', 'rapaport2', '19998', 2, 'C', 'ECONOMY'),
(29, 16, 35, 'moshe3', 'rapaport3', '29997', 3, 'D', 'FIRST'),
(30, 19, 5, 'moshe4', 'rapaport4', '39996', 4, 'E', 'BUSINESS'),
(31, 10, 11, 'moshe5', 'rapaport5', '49995', 5, 'F', 'ECONOMY'),
(32, 17, 36, 'moshe6', 'rapaport6', '59994', 6, 'A', 'FIRST'),
(33, 18, 17, 'moshe7', 'rapaport7', '69993', 7, 'B', 'BUSINESS'),
(34, 9, 24, 'moshe8', 'rapaport8', '79992', 8, 'C', 'ECONOMY'),
(35, 6, 26, 'moshe9', 'rapaport9', '89991', 9, 'D', 'FIRST'),
(36, 5, 1, 'moshe10', 'rapaport10', '99990', 10, 'E', 'BUSINESS'),
(37, 2, 31, 'moshe11', 'rapaport11', '109989', 11, 'F', 'ECONOMY'),
(38, 22, 37, 'moshe12', 'rapaport12', '119988', 12, 'A', 'FIRST'),
(39, 17, 35, 'moshe13', 'rapaport13', '129987', 13, 'B', 'BUSINESS'),
(40, 11, 2, 'moshe14', 'rapaport14', '139986', 14, 'C', 'ECONOMY'),
(41, 12, 26, 'moshe15', 'rapaport15', '149985', 15, 'D', 'FIRST'),
(42, 14, 25, 'moshe16', 'rapaport16', '159984', 16, 'E', 'BUSINESS'),
(43, 23, 10, 'moshe17', 'rapaport17', '169983', 17, 'F', 'ECONOMY'),
(44, 18, 25, 'moshe18', 'rapaport18', '179982', 18, 'A', 'FIRST'),
(45, 10, 27, 'moshe19', 'rapaport19', '189981', 19, 'B', 'BUSINESS'),
(46, 10, 37, 'moshe20', 'rapaport20', '199980', 20, 'C', 'ECONOMY'),
(47, 10, 32, 'moshe21', 'rapaport21', '209979', 21, 'D', 'FIRST'),
(48, 22, 18, 'moshe22', 'rapaport22', '219978', 22, 'E', 'BUSINESS'),
(49, 11, 10, 'moshe23', 'rapaport23', '229977', 23, 'F', 'ECONOMY'),
(50, 16, 31, 'moshe24', 'rapaport24', '239976', 24, 'A', 'FIRST'),
(51, 24, 10, 'moshe25', 'rapaport25', '249975', 25, 'B', 'BUSINESS'),
(52, 9, 24, 'moshe26', 'rapaport26', '259974', 26, 'C', 'ECONOMY'),
(53, 9, 10, 'moshe27', 'rapaport27', '269973', 27, 'D', 'FIRST'),
(54, 9, 32, 'moshe28', 'rapaport28', '279972', 28, 'E', 'BUSINESS'),
(55, 13, 37, 'moshe29', 'rapaport29', '289971', 29, 'F', 'ECONOMY'),
(56, 21, 11, 'moshe30', 'rapaport30', '299970', 30, 'A', 'FIRST'),
(57, 16, 37, 'moshe31', 'rapaport31', '309969', 31, 'B', 'BUSINESS'),
(58, 15, 19, 'moshe32', 'rapaport32', '319968', 32, 'C', 'ECONOMY'),
(59, 24, 35, 'moshe33', 'rapaport33', '329967', 33, 'D', 'FIRST'),
(60, 3, 27, 'moshe34', 'rapaport34', '339966', 34, 'E', 'BUSINESS'),
(61, 14, 32, 'moshe35', 'rapaport35', '349965', 35, 'F', 'ECONOMY'),
(62, 12, 1, 'moshe36', 'rapaport36', '359964', 36, 'A', 'FIRST'),
(63, 17, 3, 'moshe37', 'rapaport37', '369963', 37, 'B', 'BUSINESS'),
(64, 11, 31, 'moshe38', 'rapaport38', '379962', 38, 'C', 'ECONOMY'),
(65, 12, 21, 'moshe39', 'rapaport39', '389961', 39, 'D', 'FIRST'),
(66, 14, 29, 'moshe40', 'rapaport40', '399960', 40, 'E', 'BUSINESS'),
(67, 8, 36, 'moshe41', 'rapaport41', '409959', 41, 'F', 'ECONOMY'),
(68, 17, 21, 'moshe42', 'rapaport42', '419958', 42, 'A', 'FIRST'),
(69, 21, 10, 'moshe43', 'rapaport43', '429957', 43, 'B', 'BUSINESS'),
(70, 9, 34, 'moshe44', 'rapaport44', '439956', 44, 'C', 'ECONOMY'),
(71, 22, 6, 'moshe45', 'rapaport45', '449955', 45, 'D', 'FIRST'),
(72, 13, 10, 'moshe46', 'rapaport46', '459954', 46, 'E', 'BUSINESS'),
(73, 5, 21, 'moshe47', 'rapaport47', '469953', 47, 'F', 'ECONOMY'),
(74, 23, 10, 'moshe48', 'rapaport48', '479952', 48, 'A', 'FIRST'),
(75, 16, 21, 'moshe49', 'rapaport49', '489951', 49, 'B', 'BUSINESS'),
(76, 18, 21, 'moshe50', 'rapaport50', '499950', 0, 'C', 'ECONOMY'),
(77, 21, 11, 'moshe51', 'rapaport51', '509949', 1, 'D', 'FIRST'),
(78, 12, 26, 'moshe52', 'rapaport52', '519948', 2, 'E', 'BUSINESS'),
(79, 7, 27, 'moshe53', 'rapaport53', '529947', 3, 'F', 'ECONOMY'),
(80, 5, 21, 'moshe54', 'rapaport54', '539946', 4, 'A', 'FIRST'),
(81, 11, 21, 'moshe55', 'rapaport55', '549945', 5, 'B', 'BUSINESS'),
(82, 14, 18, 'moshe56', 'rapaport56', '559944', 6, 'C', 'ECONOMY'),
(83, 21, 25, 'moshe57', 'rapaport57', '569943', 7, 'D', 'FIRST'),
(84, 19, 21, 'moshe58', 'rapaport58', '579942', 8, 'E', 'BUSINESS'),
(85, 6, 21, 'moshe59', 'rapaport59', '589941', 9, 'F', 'ECONOMY'),
(86, 1, 24, 'moshe60', 'rapaport60', '599940', 10, 'A', 'FIRST'),
(87, 7, 21, 'moshe61', 'rapaport61', '609939', 11, 'B', 'BUSINESS'),
(88, 22, 3, 'moshe62', 'rapaport62', '619938', 12, 'C', 'ECONOMY'),
(89, 22, 1, 'moshe63', 'rapaport63', '629937', 13, 'D', 'FIRST'),
(90, 2, 1, 'moshe64', 'rapaport64', '639936', 14, 'E', 'BUSINESS'),
(91, 9, 21, 'moshe65', 'rapaport65', '649935', 15, 'F', 'ECONOMY'),
(92, 21, 24, 'moshe66', 'rapaport66', '659934', 16, 'A', 'FIRST'),
(93, 21, 21, 'moshe67', 'rapaport67', '669933', 17, 'B', 'BUSINESS'),
(94, 3, 35, 'moshe68', 'rapaport68', '679932', 18, 'C', 'ECONOMY'),
(95, 24, 1, 'moshe69', 'rapaport69', '689931', 19, 'D', 'FIRST'),
(96, 1, 21, 'moshe70', 'rapaport70', '699930', 20, 'E', 'BUSINESS'),
(97, 21, 27, 'moshe71', 'rapaport71', '709929', 21, 'F', 'ECONOMY'),
(98, 11, 18, 'moshe72', 'rapaport72', '719928', 22, 'A', 'FIRST'),
(99, 2, 31, 'moshe73', 'rapaport73', '729927', 23, 'B', 'BUSINESS'),
(100, 22, 29, 'moshe74', 'rapaport74', '739926', 24, 'C', 'ECONOMY'),
(101, 5, 16, 'moshe75', 'rapaport75', '749925', 25, 'D', 'FIRST'),
(102, 18, 25, 'moshe76', 'rapaport76', '759924', 26, 'E', 'BUSINESS'),
(103, 3, 27, 'moshe77', 'rapaport77', '769923', 27, 'F', 'ECONOMY'),
(104, 5, 6, 'moshe78', 'rapaport78', '779922', 28, 'A', 'FIRST'),
(105, 10, 19, 'moshe79', 'rapaport79', '789921', 29, 'B', 'BUSINESS'),
(106, 18, 18, 'moshe80', 'rapaport80', '799920', 30, 'C', 'ECONOMY'),
(107, 8, 29, 'moshe81', 'rapaport81', '809919', 31, 'D', 'FIRST'),
(108, 1, 11, 'moshe82', 'rapaport82', '819918', 32, 'E', 'BUSINESS'),
(109, 7, 11, 'moshe83', 'rapaport83', '829917', 33, 'F', 'ECONOMY'),
(110, 3, 4, 'moshe84', 'rapaport84', '839916', 34, 'A', 'FIRST'),
(111, 24, 6, 'moshe85', 'rapaport85', '849915', 35, 'B', 'BUSINESS'),
(112, 5, 36, 'moshe86', 'rapaport86', '859914', 36, 'C', 'ECONOMY'),
(113, 24, 6, 'moshe87', 'rapaport87', '869913', 37, 'D', 'FIRST'),
(114, 18, 10, 'moshe88', 'rapaport88', '879912', 38, 'E', 'BUSINESS'),
(115, 11, 26, 'moshe89', 'rapaport89', '889911', 39, 'F', 'ECONOMY'),
(116, 15, 18, 'moshe90', 'rapaport90', '899910', 40, 'A', 'FIRST'),
(117, 13, 18, 'moshe91', 'rapaport91', '909909', 41, 'B', 'BUSINESS'),
(118, 18, 17, 'moshe92', 'rapaport92', '919908', 42, 'C', 'ECONOMY'),
(119, 1, 29, 'moshe93', 'rapaport93', '929907', 43, 'D', 'FIRST'),
(120, 7, 3, 'moshe94', 'rapaport94', '939906', 44, 'E', 'BUSINESS'),
(121, 6, 10, 'moshe95', 'rapaport95', '949905', 45, 'F', 'ECONOMY'),
(122, 22, 32, 'moshe96', 'rapaport96', '959904', 46, 'A', 'FIRST'),
(123, 17, 30, 'moshe97', 'rapaport97', '969903', 47, 'B', 'BUSINESS'),
(124, 11, 6, 'moshe98', 'rapaport98', '979902', 48, 'C', 'ECONOMY'),
(125, 21, 32, 'moshe99', 'rapaport99', '989901', 49, 'D', 'FIRST'),
(126, 3, 25, 'moshe100', 'rapaport100', '999900', 0, 'E', 'BUSINESS'),
(127, 7, 31, 'moshe101', 'rapaport101', '9899', 1, 'F', 'ECONOMY'),
(128, 17, 31, 'moshe102', 'rapaport102', '19898', 2, 'A', 'FIRST'),
(129, 22, 24, 'moshe103', 'rapaport103', '29897', 3, 'B', 'BUSINESS'),
(130, 15, 17, 'moshe104', 'rapaport104', '39896', 4, 'C', 'ECONOMY'),
(131, 21, 37, 'moshe105', 'rapaport105', '49895', 5, 'D', 'FIRST'),
(132, 9, 11, 'moshe106', 'rapaport106', '59894', 6, 'E', 'BUSINESS'),
(133, 23, 21, 'moshe107', 'rapaport107', '69893', 7, 'F', 'ECONOMY'),
(134, 24, 25, 'moshe108', 'rapaport108', '79892', 8, 'A', 'FIRST'),
(135, 8, 21, 'moshe109', 'rapaport109', '89891', 9, 'B', 'BUSINESS'),
(136, 20, 26, 'moshe110', 'rapaport110', '99890', 10, 'C', 'ECONOMY'),
(137, 9, 6, 'moshe111', 'rapaport111', '109889', 11, 'D', 'FIRST'),
(138, 16, 27, 'moshe112', 'rapaport112', '119888', 12, 'E', 'BUSINESS'),
(139, 23, 18, 'moshe113', 'rapaport113', '129887', 13, 'F', 'ECONOMY'),
(140, 24, 21, 'moshe114', 'rapaport114', '139886', 14, 'A', 'FIRST'),
(141, 2, 24, 'moshe115', 'rapaport115', '149885', 15, 'B', 'BUSINESS'),
(142, 15, 18, 'moshe116', 'rapaport116', '159884', 16, 'C', 'ECONOMY'),
(143, 23, 11, 'moshe117', 'rapaport117', '169883', 17, 'D', 'FIRST'),
(144, 11, 3, 'moshe118', 'rapaport118', '179882', 18, 'E', 'BUSINESS'),
(145, 13, 21, 'moshe119', 'rapaport119', '189881', 19, 'F', 'ECONOMY'),
(146, 9, 18, 'moshe120', 'rapaport120', '199880', 20, 'A', 'FIRST'),
(147, 25, 3, 'moshe121', 'rapaport121', '209879', 21, 'B', 'BUSINESS'),
(148, 14, 11, 'moshe122', 'rapaport122', '219878', 22, 'C', 'ECONOMY'),
(149, 7, 10, 'moshe123', 'rapaport123', '229877', 23, 'D', 'FIRST'),
(150, 5, 36, 'moshe124', 'rapaport124', '239876', 24, 'E', 'BUSINESS'),
(151, 1, 35, 'moshe125', 'rapaport125', '249875', 25, 'F', 'ECONOMY'),
(152, 5, 31, 'moshe126', 'rapaport126', '259874', 26, 'A', 'FIRST'),
(153, 23, 10, 'moshe127', 'rapaport127', '269873', 27, 'B', 'BUSINESS'),
(154, 21, 21, 'moshe128', 'rapaport128', '279872', 28, 'C', 'ECONOMY'),
(155, 9, 24, 'moshe129', 'rapaport129', '289871', 29, 'D', 'FIRST'),
(156, 22, 11, 'moshe130', 'rapaport130', '299870', 30, 'E', 'BUSINESS'),
(157, 17, 11, 'moshe131', 'rapaport131', '309869', 31, 'F', 'ECONOMY'),
(158, 6, 37, 'moshe132', 'rapaport132', '319868', 32, 'A', 'FIRST'),
(159, 1, 4, 'moshe133', 'rapaport133', '329867', 33, 'B', 'BUSINESS'),
(160, 2, 31, 'moshe134', 'rapaport134', '339866', 34, 'C', 'ECONOMY'),
(161, 7, 10, 'moshe135', 'rapaport135', '349865', 35, 'D', 'FIRST'),
(162, 1, 24, 'moshe136', 'rapaport136', '359864', 36, 'E', 'BUSINESS'),
(163, 10, 36, 'moshe137', 'rapaport137', '369863', 37, 'F', 'ECONOMY'),
(164, 13, 37, 'moshe138', 'rapaport138', '379862', 38, 'A', 'FIRST'),
(165, 5, 5, 'moshe139', 'rapaport139', '389861', 39, 'B', 'BUSINESS'),
(166, 13, 35, 'moshe140', 'rapaport140', '399860', 40, 'C', 'ECONOMY'),
(167, 13, 31, 'moshe141', 'rapaport141', '409859', 41, 'D', 'FIRST'),
(168, 11, 19, 'moshe142', 'rapaport142', '419858', 42, 'E', 'BUSINESS'),
(169, 14, 21, 'moshe143', 'rapaport143', '429857', 43, 'F', 'ECONOMY'),
(170, 11, 10, 'moshe144', 'rapaport144', '439856', 44, 'A', 'FIRST'),
(171, 20, 21, 'moshe145', 'rapaport145', '449855', 45, 'B', 'BUSINESS'),
(172, 16, 27, 'moshe146', 'rapaport146', '459854', 46, 'C', 'ECONOMY'),
(173, 19, 24, 'moshe147', 'rapaport147', '469853', 47, 'D', 'FIRST'),
(174, 24, 29, 'moshe148', 'rapaport148', '479852', 48, 'E', 'BUSINESS'),
(175, 6, 10, 'moshe149', 'rapaport149', '489851', 49, 'F', 'ECONOMY'),
(176, 2, 18, 'moshe150', 'rapaport150', '499850', 0, 'A', 'FIRST'),
(177, 20, 21, 'moshe151', 'rapaport151', '509849', 1, 'B', 'BUSINESS'),
(178, 24, 26, 'moshe152', 'rapaport152', '519848', 2, 'C', 'ECONOMY'),
(179, 7, 30, 'moshe153', 'rapaport153', '529847', 3, 'D', 'FIRST'),
(180, 23, 21, 'moshe154', 'rapaport154', '539846', 4, 'E', 'BUSINESS'),
(181, 22, 18, 'moshe155', 'rapaport155', '549845', 5, 'F', 'ECONOMY'),
(182, 23, 19, 'moshe156', 'rapaport156', '559844', 6, 'A', 'FIRST'),
(183, 13, 17, 'moshe157', 'rapaport157', '569843', 7, 'B', 'BUSINESS'),
(184, 9, 16, 'moshe158', 'rapaport158', '579842', 8, 'C', 'ECONOMY'),
(185, 15, 5, 'moshe159', 'rapaport159', '589841', 9, 'D', 'FIRST'),
(186, 11, 30, 'moshe160', 'rapaport160', '599840', 10, 'E', 'BUSINESS'),
(187, 1, 32, 'moshe161', 'rapaport161', '609839', 11, 'F', 'ECONOMY'),
(188, 9, 32, 'moshe162', 'rapaport162', '619838', 12, 'A', 'FIRST'),
(189, 25, 24, 'moshe163', 'rapaport163', '629837', 13, 'B', 'BUSINESS'),
(190, 2, 11, 'moshe164', 'rapaport164', '639836', 14, 'C', 'ECONOMY'),
(191, 8, 10, 'moshe165', 'rapaport165', '649835', 15, 'D', 'FIRST'),
(192, 7, 34, 'moshe166', 'rapaport166', '659834', 16, 'E', 'BUSINESS'),
(193, 20, 34, 'moshe167', 'rapaport167', '669833', 17, 'F', 'ECONOMY'),
(194, 2, 5, 'moshe168', 'rapaport168', '679832', 18, 'A', 'FIRST'),
(195, 17, 24, 'moshe169', 'rapaport169', '689831', 19, 'B', 'BUSINESS'),
(196, 21, 11, 'moshe170', 'rapaport170', '699830', 20, 'C', 'ECONOMY'),
(197, 8, 30, 'moshe171', 'rapaport171', '709829', 21, 'D', 'FIRST'),
(198, 1, 3, 'moshe172', 'rapaport172', '719828', 22, 'E', 'BUSINESS'),
(199, 23, 26, 'moshe173', 'rapaport173', '729827', 23, 'F', 'ECONOMY'),
(200, 9, 30, 'moshe174', 'rapaport174', '739826', 24, 'A', 'FIRST'),
(201, 14, 19, 'moshe175', 'rapaport175', '749825', 25, 'B', 'BUSINESS'),
(202, 10, 21, 'moshe176', 'rapaport176', '759824', 26, 'C', 'ECONOMY'),
(203, 8, 21, 'moshe177', 'rapaport177', '769823', 27, 'D', 'FIRST'),
(204, 5, 11, 'moshe178', 'rapaport178', '779822', 28, 'E', 'BUSINESS'),
(205, 22, 25, 'moshe179', 'rapaport179', '789821', 29, 'F', 'ECONOMY'),
(206, 4, 21, 'moshe180', 'rapaport180', '799820', 30, 'A', 'FIRST'),
(207, 22, 21, 'moshe181', 'rapaport181', '809819', 31, 'B', 'BUSINESS'),
(208, 2, 19, 'moshe182', 'rapaport182', '819818', 32, 'C', 'ECONOMY'),
(209, 3, 37, 'moshe183', 'rapaport183', '829817', 33, 'D', 'FIRST'),
(210, 24, 6, 'moshe184', 'rapaport184', '839816', 34, 'E', 'BUSINESS'),
(211, 25, 21, 'moshe185', 'rapaport185', '849815', 35, 'F', 'ECONOMY'),
(212, 13, 19, 'moshe186', 'rapaport186', '859814', 36, 'A', 'FIRST'),
(213, 1, 21, 'moshe187', 'rapaport187', '869813', 37, 'B', 'BUSINESS'),
(214, 3, 25, 'moshe188', 'rapaport188', '879812', 38, 'C', 'ECONOMY'),
(215, 3, 31, 'moshe189', 'rapaport189', '889811', 39, 'D', 'FIRST'),
(216, 1, 6, 'moshe190', 'rapaport190', '899810', 40, 'E', 'BUSINESS'),
(217, 4, 35, 'moshe191', 'rapaport191', '909809', 41, 'F', 'ECONOMY'),
(218, 16, 29, 'moshe192', 'rapaport192', '919808', 42, 'A', 'FIRST'),
(219, 7, 34, 'moshe193', 'rapaport193', '929807', 43, 'B', 'BUSINESS'),
(220, 6, 30, 'moshe194', 'rapaport194', '939806', 44, 'C', 'ECONOMY'),
(221, 12, 37, 'moshe195', 'rapaport195', '949805', 45, 'D', 'FIRST'),
(222, 18, 6, 'moshe196', 'rapaport196', '959804', 46, 'E', 'BUSINESS'),
(223, 21, 18, 'moshe197', 'rapaport197', '969803', 47, 'F', 'ECONOMY'),
(224, 16, 27, 'moshe198', 'rapaport198', '979802', 48, 'A', 'FIRST'),
(225, 4, 34, 'moshe199', 'rapaport199', '989801', 49, 'B', 'BUSINESS'),
(226, 12, 32, 'moshe200', 'rapaport200', '999800', 0, 'C', 'ECONOMY'),
(227, 14, 29, 'moshe201', 'rapaport201', '9799', 1, 'D', 'FIRST'),
(228, 9, 11, 'moshe202', 'rapaport202', '19798', 2, 'E', 'BUSINESS'),
(229, 20, 16, 'moshe203', 'rapaport203', '29797', 3, 'F', 'ECONOMY'),
(230, 12, 35, 'moshe204', 'rapaport204', '39796', 4, 'A', 'FIRST'),
(231, 21, 25, 'moshe205', 'rapaport205', '49795', 5, 'B', 'BUSINESS'),
(232, 6, 18, 'moshe206', 'rapaport206', '59794', 6, 'C', 'ECONOMY'),
(233, 18, 21, 'moshe207', 'rapaport207', '69793', 7, 'D', 'FIRST'),
(234, 15, 6, 'moshe208', 'rapaport208', '79792', 8, 'E', 'BUSINESS'),
(235, 8, 19, 'moshe209', 'rapaport209', '89791', 9, 'F', 'ECONOMY'),
(236, 8, 25, 'moshe210', 'rapaport210', '99790', 10, 'A', 'FIRST'),
(237, 1, 27, 'moshe211', 'rapaport211', '109789', 11, 'B', 'BUSINESS'),
(238, 1, 19, 'moshe212', 'rapaport212', '119788', 12, 'C', 'ECONOMY'),
(239, 15, 36, 'moshe213', 'rapaport213', '129787', 13, 'D', 'FIRST'),
(240, 17, 18, 'moshe214', 'rapaport214', '139786', 14, 'E', 'BUSINESS'),
(241, 5, 25, 'moshe215', 'rapaport215', '149785', 15, 'F', 'ECONOMY'),
(242, 4, 30, 'moshe216', 'rapaport216', '159784', 16, 'A', 'FIRST'),
(243, 1, 32, 'moshe217', 'rapaport217', '169783', 17, 'B', 'BUSINESS'),
(244, 13, 18, 'moshe218', 'rapaport218', '179782', 18, 'C', 'ECONOMY'),
(245, 15, 11, 'moshe219', 'rapaport219', '189781', 19, 'D', 'FIRST'),
(246, 20, 6, 'moshe220', 'rapaport220', '199780', 20, 'E', 'BUSINESS'),
(247, 8, 34, 'moshe221', 'rapaport221', '209779', 21, 'F', 'ECONOMY'),
(248, 11, 21, 'moshe222', 'rapaport222', '219778', 22, 'A', 'FIRST'),
(249, 20, 25, 'moshe223', 'rapaport223', '229777', 23, 'B', 'BUSINESS'),
(250, 22, 29, 'moshe224', 'rapaport224', '239776', 24, 'C', 'ECONOMY'),
(251, 25, 37, 'moshe225', 'rapaport225', '249775', 25, 'D', 'FIRST'),
(252, 5, 30, 'moshe226', 'rapaport226', '259774', 26, 'E', 'BUSINESS'),
(253, 9, 4, 'moshe227', 'rapaport227', '269773', 27, 'F', 'ECONOMY'),
(254, 9, 19, 'moshe228', 'rapaport228', '279772', 28, 'A', 'FIRST'),
(255, 19, 37, 'moshe229', 'rapaport229', '289771', 29, 'B', 'BUSINESS'),
(256, 23, 37, 'moshe230', 'rapaport230', '299770', 30, 'C', 'ECONOMY'),
(257, 13, 21, 'moshe231', 'rapaport231', '309769', 31, 'D', 'FIRST'),
(258, 3, 21, 'moshe232', 'rapaport232', '319768', 32, 'E', 'BUSINESS'),
(259, 20, 25, 'moshe233', 'rapaport233', '329767', 33, 'F', 'ECONOMY'),
(260, 10, 5, 'moshe234', 'rapaport234', '339766', 34, 'A', 'FIRST'),
(261, 7, 30, 'moshe235', 'rapaport235', '349765', 35, 'B', 'BUSINESS'),
(262, 25, 19, 'moshe236', 'rapaport236', '359764', 36, 'C', 'ECONOMY'),
(263, 16, 21, 'moshe237', 'rapaport237', '369763', 37, 'D', 'FIRST'),
(264, 14, 21, 'moshe238', 'rapaport238', '379762', 38, 'E', 'BUSINESS'),
(265, 18, 24, 'moshe239', 'rapaport239', '389761', 39, 'F', 'ECONOMY'),
(266, 8, 34, 'moshe240', 'rapaport240', '399760', 40, 'A', 'FIRST'),
(267, 25, 1, 'moshe241', 'rapaport241', '409759', 41, 'B', 'BUSINESS'),
(268, 2, 11, 'moshe242', 'rapaport242', '419758', 42, 'C', 'ECONOMY'),
(269, 23, 11, 'moshe243', 'rapaport243', '429757', 43, 'D', 'FIRST'),
(270, 8, 6, 'moshe244', 'rapaport244', '439756', 44, 'E', 'BUSINESS'),
(271, 9, 1, 'moshe245', 'rapaport245', '449755', 45, 'F', 'ECONOMY'),
(272, 13, 10, 'moshe246', 'rapaport246', '459754', 46, 'A', 'FIRST'),
(273, 20, 6, 'moshe247', 'rapaport247', '469753', 47, 'B', 'BUSINESS'),
(274, 6, 11, 'moshe248', 'rapaport248', '479752', 48, 'C', 'ECONOMY'),
(275, 2, 32, 'moshe249', 'rapaport249', '489751', 49, 'D', 'FIRST'),
(276, 3, 24, 'moshe250', 'rapaport250', '499750', 0, 'E', 'BUSINESS'),
(277, 15, 11, 'moshe251', 'rapaport251', '509749', 1, 'F', 'ECONOMY'),
(278, 6, 21, 'moshe252', 'rapaport252', '519748', 2, 'A', 'FIRST'),
(279, 21, 24, 'moshe253', 'rapaport253', '529747', 3, 'B', 'BUSINESS'),
(280, 21, 18, 'moshe254', 'rapaport254', '539746', 4, 'C', 'ECONOMY'),
(281, 2, 24, 'moshe255', 'rapaport255', '549745', 5, 'D', 'FIRST'),
(282, 20, 36, 'moshe256', 'rapaport256', '559744', 6, 'E', 'BUSINESS'),
(283, 23, 18, 'moshe257', 'rapaport257', '569743', 7, 'F', 'ECONOMY'),
(284, 9, 11, 'moshe258', 'rapaport258', '579742', 8, 'A', 'FIRST'),
(285, 1, 25, 'moshe259', 'rapaport259', '589741', 9, 'B', 'BUSINESS'),
(286, 8, 24, 'moshe260', 'rapaport260', '599740', 10, 'C', 'ECONOMY'),
(287, 20, 3, 'moshe261', 'rapaport261', '609739', 11, 'D', 'FIRST'),
(288, 7, 21, 'moshe262', 'rapaport262', '619738', 12, 'E', 'BUSINESS'),
(289, 5, 5, 'moshe263', 'rapaport263', '629737', 13, 'F', 'ECONOMY'),
(290, 9, 31, 'moshe264', 'rapaport264', '639736', 14, 'A', 'FIRST'),
(291, 7, 36, 'moshe265', 'rapaport265', '649735', 15, 'B', 'BUSINESS'),
(292, 21, 29, 'moshe266', 'rapaport266', '659734', 16, 'C', 'ECONOMY'),
(293, 19, 6, 'moshe267', 'rapaport267', '669733', 17, 'D', 'FIRST'),
(294, 6, 25, 'moshe268', 'rapaport268', '679732', 18, 'E', 'BUSINESS'),
(295, 23, 16, 'moshe269', 'rapaport269', '689731', 19, 'F', 'ECONOMY'),
(296, 20, 19, 'moshe270', 'rapaport270', '699730', 20, 'A', 'FIRST'),
(297, 4, 25, 'moshe271', 'rapaport271', '709729', 21, 'B', 'BUSINESS'),
(298, 13, 34, 'moshe272', 'rapaport272', '719728', 22, 'C', 'ECONOMY'),
(299, 12, 26, 'moshe273', 'rapaport273', '729727', 23, 'D', 'FIRST'),
(300, 22, 5, 'moshe274', 'rapaport274', '739726', 24, 'E', 'BUSINESS'),
(301, 22, 35, 'moshe275', 'rapaport275', '749725', 25, 'F', 'ECONOMY'),
(302, 12, 25, 'moshe276', 'rapaport276', '759724', 26, 'A', 'FIRST'),
(303, 7, 21, 'moshe277', 'rapaport277', '769723', 27, 'B', 'BUSINESS'),
(304, 4, 37, 'moshe278', 'rapaport278', '779722', 28, 'C', 'ECONOMY'),
(305, 12, 24, 'moshe279', 'rapaport279', '789721', 29, 'D', 'FIRST'),
(306, 9, 10, 'moshe280', 'rapaport280', '799720', 30, 'E', 'BUSINESS'),
(307, 18, 24, 'moshe281', 'rapaport281', '809719', 31, 'F', 'ECONOMY'),
(308, 21, 32, 'moshe282', 'rapaport282', '819718', 32, 'A', 'FIRST'),
(309, 3, 32, 'moshe283', 'rapaport283', '829717', 33, 'B', 'BUSINESS'),
(310, 11, 30, 'moshe284', 'rapaport284', '839716', 34, 'C', 'ECONOMY'),
(311, 16, 6, 'moshe285', 'rapaport285', '849715', 35, 'D', 'FIRST'),
(312, 5, 18, 'moshe286', 'rapaport286', '859714', 36, 'E', 'BUSINESS'),
(313, 20, 29, 'moshe287', 'rapaport287', '869713', 37, 'F', 'ECONOMY'),
(314, 10, 4, 'moshe288', 'rapaport288', '879712', 38, 'A', 'FIRST'),
(315, 23, 37, 'moshe289', 'rapaport289', '889711', 39, 'B', 'BUSINESS'),
(316, 14, 36, 'moshe290', 'rapaport290', '899710', 40, 'C', 'ECONOMY'),
(317, 3, 24, 'moshe291', 'rapaport291', '909709', 41, 'D', 'FIRST'),
(318, 22, 18, 'moshe292', 'rapaport292', '919708', 42, 'E', 'BUSINESS'),
(319, 8, 37, 'moshe293', 'rapaport293', '929707', 43, 'F', 'ECONOMY'),
(320, 6, 11, 'moshe294', 'rapaport294', '939706', 44, 'A', 'FIRST'),
(321, 8, 17, 'moshe295', 'rapaport295', '949705', 45, 'B', 'BUSINESS'),
(322, 22, 5, 'moshe296', 'rapaport296', '959704', 46, 'C', 'ECONOMY'),
(323, 12, 26, 'moshe297', 'rapaport297', '969703', 47, 'D', 'FIRST'),
(324, 20, 11, 'moshe298', 'rapaport298', '979702', 48, 'E', 'BUSINESS'),
(325, 17, 30, 'moshe299', 'rapaport299', '989701', 49, 'F', 'ECONOMY'),
(326, 18, 26, 'moshe300', 'rapaport300', '999700', 0, 'A', 'FIRST'),
(327, 22, 25, 'moshe301', 'rapaport301', '9699', 1, 'B', 'BUSINESS'),
(328, 11, 1, 'moshe302', 'rapaport302', '19698', 2, 'C', 'ECONOMY'),
(329, 12, 27, 'moshe303', 'rapaport303', '29697', 3, 'D', 'FIRST'),
(330, 19, 24, 'moshe304', 'rapaport304', '39696', 4, 'E', 'BUSINESS'),
(331, 7, 17, 'moshe305', 'rapaport305', '49695', 5, 'F', 'ECONOMY'),
(332, 10, 21, 'moshe306', 'rapaport306', '59694', 6, 'A', 'FIRST'),
(333, 19, 31, 'moshe307', 'rapaport307', '69693', 7, 'B', 'BUSINESS'),
(334, 14, 31, 'moshe308', 'rapaport308', '79692', 8, 'C', 'ECONOMY'),
(335, 25, 37, 'moshe309', 'rapaport309', '89691', 9, 'D', 'FIRST'),
(336, 8, 3, 'moshe310', 'rapaport310', '99690', 10, 'E', 'BUSINESS'),
(337, 18, 26, 'moshe311', 'rapaport311', '109689', 11, 'F', 'ECONOMY'),
(338, 16, 21, 'moshe312', 'rapaport312', '119688', 12, 'A', 'FIRST'),
(339, 5, 1, 'moshe313', 'rapaport313', '129687', 13, 'B', 'BUSINESS'),
(340, 9, 11, 'moshe314', 'rapaport314', '139686', 14, 'C', 'ECONOMY'),
(341, 10, 37, 'moshe315', 'rapaport315', '149685', 15, 'D', 'FIRST'),
(342, 5, 11, 'moshe316', 'rapaport316', '159684', 16, 'E', 'BUSINESS'),
(343, 13, 34, 'moshe317', 'rapaport317', '169683', 17, 'F', 'ECONOMY'),
(344, 13, 21, 'moshe318', 'rapaport318', '179682', 18, 'A', 'FIRST'),
(345, 6, 16, 'moshe319', 'rapaport319', '189681', 19, 'B', 'BUSINESS'),
(346, 7, 37, 'moshe320', 'rapaport320', '199680', 20, 'C', 'ECONOMY'),
(347, 4, 37, 'moshe321', 'rapaport321', '209679', 21, 'D', 'FIRST'),
(348, 14, 21, 'moshe322', 'rapaport322', '219678', 22, 'E', 'BUSINESS'),
(349, 9, 21, 'moshe323', 'rapaport323', '229677', 23, 'F', 'ECONOMY'),
(350, 23, 11, 'moshe324', 'rapaport324', '239676', 24, 'A', 'FIRST'),
(351, 20, 32, 'moshe325', 'rapaport325', '249675', 25, 'B', 'BUSINESS'),
(352, 8, 21, 'moshe326', 'rapaport326', '259674', 26, 'C', 'ECONOMY'),
(353, 19, 24, 'moshe327', 'rapaport327', '269673', 27, 'D', 'FIRST'),
(354, 17, 11, 'moshe328', 'rapaport328', '279672', 28, 'E', 'BUSINESS'),
(355, 1, 10, 'moshe329', 'rapaport329', '289671', 29, 'F', 'ECONOMY'),
(356, 19, 35, 'moshe330', 'rapaport330', '299670', 30, 'A', 'FIRST'),
(357, 15, 18, 'moshe331', 'rapaport331', '309669', 31, 'B', 'BUSINESS'),
(358, 17, 18, 'moshe332', 'rapaport332', '319668', 32, 'C', 'ECONOMY'),
(359, 23, 26, 'moshe333', 'rapaport333', '329667', 33, 'D', 'FIRST'),
(360, 3, 5, 'moshe334', 'rapaport334', '339666', 34, 'E', 'BUSINESS'),
(361, 17, 35, 'moshe335', 'rapaport335', '349665', 35, 'F', 'ECONOMY'),
(362, 24, 21, 'moshe336', 'rapaport336', '359664', 36, 'A', 'FIRST'),
(363, 14, 26, 'moshe337', 'rapaport337', '369663', 37, 'B', 'BUSINESS'),
(364, 12, 37, 'moshe338', 'rapaport338', '379662', 38, 'C', 'ECONOMY'),
(365, 25, 21, 'moshe339', 'rapaport339', '389661', 39, 'D', 'FIRST'),
(366, 18, 10, 'moshe340', 'rapaport340', '399660', 40, 'E', 'BUSINESS'),
(367, 3, 16, 'moshe341', 'rapaport341', '409659', 41, 'F', 'ECONOMY'),
(368, 4, 1, 'moshe342', 'rapaport342', '419658', 42, 'A', 'FIRST'),
(369, 24, 36, 'moshe343', 'rapaport343', '429657', 43, 'B', 'BUSINESS'),
(370, 17, 11, 'moshe344', 'rapaport344', '439656', 44, 'C', 'ECONOMY'),
(371, 2, 11, 'moshe345', 'rapaport345', '449655', 45, 'D', 'FIRST'),
(372, 10, 37, 'moshe346', 'rapaport346', '459654', 46, 'E', 'BUSINESS'),
(373, 22, 27, 'moshe347', 'rapaport347', '469653', 47, 'F', 'ECONOMY'),
(374, 15, 29, 'moshe348', 'rapaport348', '479652', 48, 'A', 'FIRST'),
(375, 17, 6, 'moshe349', 'rapaport349', '489651', 49, 'B', 'BUSINESS'),
(376, 13, 21, 'moshe350', 'rapaport350', '499650', 0, 'C', 'ECONOMY'),
(377, 17, 6, 'moshe351', 'rapaport351', '509649', 1, 'D', 'FIRST'),
(378, 23, 30, 'moshe352', 'rapaport352', '519648', 2, 'E', 'BUSINESS'),
(379, 13, 25, 'moshe353', 'rapaport353', '529647', 3, 'F', 'ECONOMY'),
(380, 23, 30, 'moshe354', 'rapaport354', '539646', 4, 'A', 'FIRST'),
(381, 13, 19, 'moshe355', 'rapaport355', '549645', 5, 'B', 'BUSINESS'),
(382, 8, 10, 'moshe356', 'rapaport356', '559644', 6, 'C', 'ECONOMY'),
(383, 17, 19, 'moshe357', 'rapaport357', '569643', 7, 'D', 'FIRST'),
(384, 25, 25, 'moshe358', 'rapaport358', '579642', 8, 'E', 'BUSINESS'),
(385, 5, 18, 'moshe359', 'rapaport359', '589641', 9, 'F', 'ECONOMY'),
(386, 8, 11, 'moshe360', 'rapaport360', '599640', 10, 'A', 'FIRST'),
(387, 2, 26, 'moshe361', 'rapaport361', '609639', 11, 'B', 'BUSINESS'),
(388, 19, 21, 'moshe362', 'rapaport362', '619638', 12, 'C', 'ECONOMY'),
(389, 4, 35, 'moshe363', 'rapaport363', '629637', 13, 'D', 'FIRST'),
(390, 8, 17, 'moshe364', 'rapaport364', '639636', 14, 'E', 'BUSINESS'),
(391, 8, 10, 'moshe365', 'rapaport365', '649635', 15, 'F', 'ECONOMY'),
(392, 2, 24, 'moshe366', 'rapaport366', '659634', 16, 'A', 'FIRST'),
(393, 3, 6, 'moshe367', 'rapaport367', '669633', 17, 'B', 'BUSINESS'),
(394, 25, 19, 'moshe368', 'rapaport368', '679632', 18, 'C', 'ECONOMY'),
(395, 17, 10, 'moshe369', 'rapaport369', '689631', 19, 'D', 'FIRST'),
(396, 25, 10, 'moshe370', 'rapaport370', '699630', 20, 'E', 'BUSINESS'),
(397, 15, 19, 'moshe371', 'rapaport371', '709629', 21, 'F', 'ECONOMY'),
(398, 3, 30, 'moshe372', 'rapaport372', '719628', 22, 'A', 'FIRST'),
(399, 11, 21, 'moshe373', 'rapaport373', '729627', 23, 'B', 'BUSINESS'),
(400, 16, 19, 'moshe374', 'rapaport374', '739626', 24, 'C', 'ECONOMY'),
(401, 4, 10, 'moshe375', 'rapaport375', '749625', 25, 'D', 'FIRST'),
(402, 23, 4, 'moshe376', 'rapaport376', '759624', 26, 'E', 'BUSINESS'),
(403, 19, 26, 'moshe377', 'rapaport377', '769623', 27, 'F', 'ECONOMY'),
(404, 5, 26, 'moshe378', 'rapaport378', '779622', 28, 'A', 'FIRST'),
(405, 17, 29, 'moshe379', 'rapaport379', '789621', 29, 'B', 'BUSINESS'),
(406, 11, 26, 'moshe380', 'rapaport380', '799620', 30, 'C', 'ECONOMY'),
(407, 7, 26, 'moshe381', 'rapaport381', '809619', 31, 'D', 'FIRST'),
(408, 17, 4, 'moshe382', 'rapaport382', '819618', 32, 'E', 'BUSINESS'),
(409, 22, 21, 'moshe383', 'rapaport383', '829617', 33, 'F', 'ECONOMY'),
(410, 5, 26, 'moshe384', 'rapaport384', '839616', 34, 'A', 'FIRST'),
(411, 25, 21, 'moshe385', 'rapaport385', '849615', 35, 'B', 'BUSINESS'),
(412, 11, 26, 'moshe386', 'rapaport386', '859614', 36, 'C', 'ECONOMY'),
(413, 25, 31, 'moshe387', 'rapaport387', '869613', 37, 'D', 'FIRST'),
(414, 18, 18, 'moshe388', 'rapaport388', '879612', 38, 'E', 'BUSINESS'),
(415, 18, 10, 'moshe389', 'rapaport389', '889611', 39, 'F', 'ECONOMY'),
(416, 3, 27, 'moshe390', 'rapaport390', '899610', 40, 'A', 'FIRST'),
(417, 12, 25, 'moshe391', 'rapaport391', '909609', 41, 'B', 'BUSINESS'),
(418, 7, 11, 'moshe392', 'rapaport392', '919608', 42, 'C', 'ECONOMY'),
(419, 4, 11, 'moshe393', 'rapaport393', '929607', 43, 'D', 'FIRST'),
(420, 13, 37, 'moshe394', 'rapaport394', '939606', 44, 'E', 'BUSINESS'),
(421, 17, 18, 'moshe395', 'rapaport395', '949605', 45, 'F', 'ECONOMY'),
(422, 16, 3, 'moshe396', 'rapaport396', '959604', 46, 'A', 'FIRST'),
(423, 18, 34, 'moshe397', 'rapaport397', '969603', 47, 'B', 'BUSINESS'),
(424, 5, 30, 'moshe398', 'rapaport398', '979602', 48, 'C', 'ECONOMY'),
(425, 14, 10, 'moshe399', 'rapaport399', '989601', 49, 'D', 'FIRST'),
(426, 17, 29, 'moshe400', 'rapaport400', '999600', 0, 'E', 'BUSINESS'),
(427, 13, 5, 'moshe401', 'rapaport401', '9599', 1, 'F', 'ECONOMY'),
(428, 16, 29, 'moshe402', 'rapaport402', '19598', 2, 'A', 'FIRST'),
(429, 4, 10, 'moshe403', 'rapaport403', '29597', 3, 'B', 'BUSINESS'),
(430, 15, 29, 'moshe404', 'rapaport404', '39596', 4, 'C', 'ECONOMY'),
(431, 12, 21, 'moshe405', 'rapaport405', '49595', 5, 'D', 'FIRST'),
(432, 16, 6, 'moshe406', 'rapaport406', '59594', 6, 'E', 'BUSINESS'),
(433, 16, 32, 'moshe407', 'rapaport407', '69593', 7, 'F', 'ECONOMY'),
(434, 7, 5, 'moshe408', 'rapaport408', '79592', 8, 'A', 'FIRST'),
(435, 24, 26, 'moshe409', 'rapaport409', '89591', 9, 'B', 'BUSINESS'),
(436, 18, 3, 'moshe410', 'rapaport410', '99590', 10, 'C', 'ECONOMY'),
(437, 25, 32, 'moshe411', 'rapaport411', '109589', 11, 'D', 'FIRST'),
(438, 24, 21, 'moshe412', 'rapaport412', '119588', 12, 'E', 'BUSINESS'),
(439, 8, 21, 'moshe413', 'rapaport413', '129587', 13, 'F', 'ECONOMY'),
(440, 8, 36, 'moshe414', 'rapaport414', '139586', 14, 'A', 'FIRST'),
(441, 8, 10, 'moshe415', 'rapaport415', '149585', 15, 'B', 'BUSINESS'),
(442, 16, 1, 'moshe416', 'rapaport416', '159584', 16, 'C', 'ECONOMY'),
(443, 3, 1, 'moshe417', 'rapaport417', '169583', 17, 'D', 'FIRST'),
(444, 23, 17, 'moshe418', 'rapaport418', '179582', 18, 'E', 'BUSINESS'),
(445, 19, 25, 'moshe419', 'rapaport419', '189581', 19, 'F', 'ECONOMY'),
(446, 24, 24, 'moshe420', 'rapaport420', '199580', 20, 'A', 'FIRST'),
(447, 18, 26, 'moshe421', 'rapaport421', '209579', 21, 'B', 'BUSINESS'),
(448, 2, 19, 'moshe422', 'rapaport422', '219578', 22, 'C', 'ECONOMY'),
(449, 25, 10, 'moshe423', 'rapaport423', '229577', 23, 'D', 'FIRST'),
(450, 3, 19, 'moshe424', 'rapaport424', '239576', 24, 'E', 'BUSINESS'),
(451, 7, 21, 'moshe425', 'rapaport425', '249575', 25, 'F', 'ECONOMY'),
(452, 1, 27, 'moshe426', 'rapaport426', '259574', 26, 'A', 'FIRST'),
(453, 21, 26, 'moshe427', 'rapaport427', '269573', 27, 'B', 'BUSINESS'),
(454, 20, 10, 'moshe428', 'rapaport428', '279572', 28, 'C', 'ECONOMY'),
(455, 3, 26, 'moshe429', 'rapaport429', '289571', 29, 'D', 'FIRST'),
(456, 1, 24, 'moshe430', 'rapaport430', '299570', 30, 'E', 'BUSINESS'),
(457, 19, 3, 'moshe431', 'rapaport431', '309569', 31, 'F', 'ECONOMY'),
(458, 23, 21, 'moshe432', 'rapaport432', '319568', 32, 'A', 'FIRST'),
(459, 20, 21, 'moshe433', 'rapaport433', '329567', 33, 'B', 'BUSINESS'),
(460, 15, 35, 'moshe434', 'rapaport434', '339566', 34, 'C', 'ECONOMY'),
(461, 17, 2, 'moshe435', 'rapaport435', '349565', 35, 'D', 'FIRST'),
(462, 1, 16, 'moshe436', 'rapaport436', '359564', 36, 'E', 'BUSINESS'),
(463, 19, 31, 'moshe437', 'rapaport437', '369563', 37, 'F', 'ECONOMY'),
(464, 9, 37, 'moshe438', 'rapaport438', '379562', 38, 'A', 'FIRST'),
(465, 4, 32, 'moshe439', 'rapaport439', '389561', 39, 'B', 'BUSINESS'),
(466, 22, 30, 'moshe440', 'rapaport440', '399560', 40, 'C', 'ECONOMY'),
(467, 7, 10, 'moshe441', 'rapaport441', '409559', 41, 'D', 'FIRST'),
(468, 8, 10, 'moshe442', 'rapaport442', '419558', 42, 'E', 'BUSINESS'),
(469, 22, 37, 'moshe443', 'rapaport443', '429557', 43, 'F', 'ECONOMY'),
(470, 5, 16, 'moshe444', 'rapaport444', '439556', 44, 'A', 'FIRST'),
(471, 14, 30, 'moshe445', 'rapaport445', '449555', 45, 'B', 'BUSINESS'),
(472, 13, 5, 'moshe446', 'rapaport446', '459554', 46, 'C', 'ECONOMY'),
(473, 22, 18, 'moshe447', 'rapaport447', '469553', 47, 'D', 'FIRST'),
(474, 21, 21, 'moshe448', 'rapaport448', '479552', 48, 'E', 'BUSINESS'),
(475, 4, 36, 'moshe449', 'rapaport449', '489551', 49, 'F', 'ECONOMY'),
(476, 3, 25, 'moshe450', 'rapaport450', '499550', 0, 'A', 'FIRST'),
(477, 7, 10, 'moshe451', 'rapaport451', '509549', 1, 'B', 'BUSINESS'),
(478, 13, 35, 'moshe452', 'rapaport452', '519548', 2, 'C', 'ECONOMY'),
(479, 6, 21, 'moshe453', 'rapaport453', '529547', 3, 'D', 'FIRST'),
(480, 17, 1, 'moshe454', 'rapaport454', '539546', 4, 'E', 'BUSINESS'),
(481, 3, 21, 'moshe455', 'rapaport455', '549545', 5, 'F', 'ECONOMY'),
(482, 23, 11, 'moshe456', 'rapaport456', '559544', 6, 'A', 'FIRST'),
(483, 21, 16, 'moshe457', 'rapaport457', '569543', 7, 'B', 'BUSINESS'),
(484, 9, 17, 'moshe458', 'rapaport458', '579542', 8, 'C', 'ECONOMY'),
(485, 14, 36, 'moshe459', 'rapaport459', '589541', 9, 'D', 'FIRST'),
(486, 20, 32, 'moshe460', 'rapaport460', '599540', 10, 'E', 'BUSINESS'),
(487, 13, 10, 'moshe461', 'rapaport461', '609539', 11, 'F', 'ECONOMY'),
(488, 4, 30, 'moshe462', 'rapaport462', '619538', 12, 'A', 'FIRST'),
(489, 22, 6, 'moshe463', 'rapaport463', '629537', 13, 'B', 'BUSINESS'),
(490, 15, 27, 'moshe464', 'rapaport464', '639536', 14, 'C', 'ECONOMY'),
(491, 10, 21, 'moshe465', 'rapaport465', '649535', 15, 'D', 'FIRST'),
(492, 24, 37, 'moshe466', 'rapaport466', '659534', 16, 'E', 'BUSINESS'),
(493, 10, 18, 'moshe467', 'rapaport467', '669533', 17, 'F', 'ECONOMY'),
(494, 3, 11, 'moshe468', 'rapaport468', '679532', 18, 'A', 'FIRST'),
(495, 13, 32, 'moshe469', 'rapaport469', '689531', 19, 'B', 'BUSINESS'),
(496, 15, 29, 'moshe470', 'rapaport470', '699530', 20, 'C', 'ECONOMY'),
(497, 9, 30, 'moshe471', 'rapaport471', '709529', 21, 'D', 'FIRST'),
(498, 1, 21, 'moshe472', 'rapaport472', '719528', 22, 'E', 'BUSINESS'),
(499, 18, 16, 'moshe473', 'rapaport473', '729527', 23, 'F', 'ECONOMY'),
(500, 1, 11, 'moshe474', 'rapaport474', '739526', 24, 'A', 'FIRST'),
(501, 9, 24, 'moshe475', 'rapaport475', '749525', 25, 'B', 'BUSINESS'),
(502, 8, 21, 'moshe476', 'rapaport476', '759524', 26, 'C', 'ECONOMY'),
(503, 11, 17, 'moshe477', 'rapaport477', '769523', 27, 'D', 'FIRST'),
(504, 14, 27, 'moshe478', 'rapaport478', '779522', 28, 'E', 'BUSINESS'),
(505, 4, 5, 'moshe479', 'rapaport479', '789521', 29, 'F', 'ECONOMY'),
(506, 9, 30, 'moshe480', 'rapaport480', '799520', 30, 'A', 'FIRST'),
(507, 21, 25, 'moshe481', 'rapaport481', '809519', 31, 'B', 'BUSINESS'),
(508, 24, 36, 'moshe482', 'rapaport482', '819518', 32, 'C', 'ECONOMY'),
(509, 16, 11, 'moshe483', 'rapaport483', '829517', 33, 'D', 'FIRST'),
(510, 24, 3, 'moshe484', 'rapaport484', '839516', 34, 'E', 'BUSINESS'),
(511, 18, 24, 'moshe485', 'rapaport485', '849515', 35, 'F', 'ECONOMY'),
(512, 14, 16, 'moshe486', 'rapaport486', '859514', 36, 'A', 'FIRST'),
(513, 9, 10, 'moshe487', 'rapaport487', '869513', 37, 'B', 'BUSINESS'),
(514, 13, 32, 'moshe488', 'rapaport488', '879512', 38, 'C', 'ECONOMY'),
(515, 19, 35, 'moshe489', 'rapaport489', '889511', 39, 'D', 'FIRST'),
(516, 24, 21, 'moshe490', 'rapaport490', '899510', 40, 'E', 'BUSINESS'),
(517, 19, 31, 'moshe491', 'rapaport491', '909509', 41, 'F', 'ECONOMY'),
(518, 9, 32, 'moshe492', 'rapaport492', '919508', 42, 'A', 'FIRST'),
(519, 18, 29, 'moshe493', 'rapaport493', '929507', 43, 'B', 'BUSINESS'),
(520, 5, 21, 'moshe494', 'rapaport494', '939506', 44, 'C', 'ECONOMY'),
(521, 14, 19, 'moshe495', 'rapaport495', '949505', 45, 'D', 'FIRST'),
(522, 11, 18, 'moshe496', 'rapaport496', '959504', 46, 'E', 'BUSINESS'),
(523, 19, 3, 'moshe497', 'rapaport497', '969503', 47, 'F', 'ECONOMY'),
(524, 16, 21, 'moshe498', 'rapaport498', '979502', 48, 'A', 'FIRST'),
(525, 23, 25, 'moshe499', 'rapaport499', '989501', 49, 'B', 'BUSINESS'),
(526, 21, 3, 'moshe500', 'rapaport500', '999500', 0, 'C', 'ECONOMY'),
(527, 25, 2, 'moshe501', 'rapaport501', '9499', 1, 'D', 'FIRST'),
(528, 10, 36, 'moshe502', 'rapaport502', '19498', 2, 'E', 'BUSINESS'),
(529, 2, 30, 'moshe503', 'rapaport503', '29497', 3, 'F', 'ECONOMY'),
(530, 12, 5, 'moshe504', 'rapaport504', '39496', 4, 'A', 'FIRST'),
(531, 20, 21, 'moshe505', 'rapaport505', '49495', 5, 'B', 'BUSINESS'),
(532, 7, 26, 'moshe506', 'rapaport506', '59494', 6, 'C', 'ECONOMY'),
(533, 1, 17, 'moshe507', 'rapaport507', '69493', 7, 'D', 'FIRST'),
(534, 4, 34, 'moshe508', 'rapaport508', '79492', 8, 'E', 'BUSINESS'),
(535, 4, 35, 'moshe509', 'rapaport509', '89491', 9, 'F', 'ECONOMY'),
(536, 1, 5, 'moshe510', 'rapaport510', '99490', 10, 'A', 'FIRST'),
(537, 4, 35, 'moshe511', 'rapaport511', '109489', 11, 'B', 'BUSINESS'),
(538, 17, 16, 'moshe512', 'rapaport512', '119488', 12, 'C', 'ECONOMY'),
(539, 14, 34, 'moshe513', 'rapaport513', '129487', 13, 'D', 'FIRST'),
(540, 9, 24, 'moshe514', 'rapaport514', '139486', 14, 'E', 'BUSINESS'),
(541, 10, 25, 'moshe515', 'rapaport515', '149485', 15, 'F', 'ECONOMY'),
(542, 6, 25, 'moshe516', 'rapaport516', '159484', 16, 'A', 'FIRST'),
(543, 25, 11, 'moshe517', 'rapaport517', '169483', 17, 'B', 'BUSINESS'),
(544, 18, 25, 'moshe518', 'rapaport518', '179482', 18, 'C', 'ECONOMY'),
(545, 1, 11, 'moshe519', 'rapaport519', '189481', 19, 'D', 'FIRST'),
(546, 2, 21, 'moshe520', 'rapaport520', '199480', 20, 'E', 'BUSINESS'),
(547, 24, 10, 'moshe521', 'rapaport521', '209479', 21, 'F', 'ECONOMY'),
(548, 12, 11, 'moshe522', 'rapaport522', '219478', 22, 'A', 'FIRST'),
(549, 5, 19, 'moshe523', 'rapaport523', '229477', 23, 'B', 'BUSINESS'),
(550, 25, 10, 'moshe524', 'rapaport524', '239476', 24, 'C', 'ECONOMY'),
(551, 12, 19, 'moshe525', 'rapaport525', '249475', 25, 'D', 'FIRST'),
(552, 17, 26, 'moshe526', 'rapaport526', '259474', 26, 'E', 'BUSINESS'),
(553, 12, 17, 'moshe527', 'rapaport527', '269473', 27, 'F', 'ECONOMY'),
(554, 11, 31, 'moshe528', 'rapaport528', '279472', 28, 'A', 'FIRST'),
(555, 8, 21, 'moshe529', 'rapaport529', '289471', 29, 'B', 'BUSINESS'),
(556, 16, 25, 'moshe530', 'rapaport530', '299470', 30, 'C', 'ECONOMY'),
(557, 8, 11, 'moshe531', 'rapaport531', '309469', 31, 'D', 'FIRST'),
(558, 9, 21, 'moshe532', 'rapaport532', '319468', 32, 'E', 'BUSINESS'),
(559, 11, 16, 'moshe533', 'rapaport533', '329467', 33, 'F', 'ECONOMY'),
(560, 1, 21, 'moshe534', 'rapaport534', '339466', 34, 'A', 'FIRST'),
(561, 15, 36, 'moshe535', 'rapaport535', '349465', 35, 'B', 'BUSINESS'),
(562, 16, 35, 'moshe536', 'rapaport536', '359464', 36, 'C', 'ECONOMY'),
(563, 14, 31, 'moshe537', 'rapaport537', '369463', 37, 'D', 'FIRST'),
(564, 5, 35, 'moshe538', 'rapaport538', '379462', 38, 'E', 'BUSINESS'),
(565, 20, 25, 'moshe539', 'rapaport539', '389461', 39, 'F', 'ECONOMY'),
(566, 2, 19, 'moshe540', 'rapaport540', '399460', 40, 'A', 'FIRST'),
(567, 4, 29, 'moshe541', 'rapaport541', '409459', 41, 'B', 'BUSINESS'),
(568, 11, 21, 'moshe542', 'rapaport542', '419458', 42, 'C', 'ECONOMY'),
(569, 22, 35, 'moshe543', 'rapaport543', '429457', 43, 'D', 'FIRST'),
(570, 23, 21, 'moshe544', 'rapaport544', '439456', 44, 'E', 'BUSINESS'),
(571, 6, 29, 'moshe545', 'rapaport545', '449455', 45, 'F', 'ECONOMY'),
(572, 22, 11, 'moshe546', 'rapaport546', '459454', 46, 'A', 'FIRST'),
(573, 14, 10, 'moshe547', 'rapaport547', '469453', 47, 'B', 'BUSINESS'),
(574, 11, 2, 'moshe548', 'rapaport548', '479452', 48, 'C', 'ECONOMY'),
(575, 11, 16, 'moshe549', 'rapaport549', '489451', 49, 'D', 'FIRST'),
(576, 6, 16, 'moshe550', 'rapaport550', '499450', 0, 'E', 'BUSINESS'),
(577, 12, 36, 'moshe551', 'rapaport551', '509449', 1, 'F', 'ECONOMY'),
(578, 4, 16, 'moshe552', 'rapaport552', '519448', 2, 'A', 'FIRST'),
(579, 13, 16, 'moshe553', 'rapaport553', '529447', 3, 'B', 'BUSINESS'),
(580, 22, 31, 'moshe554', 'rapaport554', '539446', 4, 'C', 'ECONOMY'),
(581, 10, 21, 'moshe555', 'rapaport555', '549445', 5, 'D', 'FIRST'),
(582, 13, 17, 'moshe556', 'rapaport556', '559444', 6, 'E', 'BUSINESS'),
(583, 5, 11, 'moshe557', 'rapaport557', '569443', 7, 'F', 'ECONOMY'),
(584, 25, 29, 'moshe558', 'rapaport558', '579442', 8, 'A', 'FIRST'),
(585, 1, 32, 'moshe559', 'rapaport559', '589441', 9, 'B', 'BUSINESS'),
(586, 20, 37, 'moshe560', 'rapaport560', '599440', 10, 'C', 'ECONOMY'),
(587, 11, 18, 'moshe561', 'rapaport561', '609439', 11, 'D', 'FIRST'),
(588, 24, 29, 'moshe562', 'rapaport562', '619438', 12, 'E', 'BUSINESS'),
(589, 15, 29, 'moshe563', 'rapaport563', '629437', 13, 'F', 'ECONOMY'),
(590, 14, 31, 'moshe564', 'rapaport564', '639436', 14, 'A', 'FIRST'),
(591, 17, 4, 'moshe565', 'rapaport565', '649435', 15, 'B', 'BUSINESS'),
(592, 10, 11, 'moshe566', 'rapaport566', '659434', 16, 'C', 'ECONOMY'),
(593, 4, 34, 'moshe567', 'rapaport567', '669433', 17, 'D', 'FIRST'),
(594, 4, 21, 'moshe568', 'rapaport568', '679432', 18, 'E', 'BUSINESS'),
(595, 4, 21, 'moshe569', 'rapaport569', '689431', 19, 'F', 'ECONOMY'),
(596, 17, 2, 'moshe570', 'rapaport570', '699430', 20, 'A', 'FIRST'),
(597, 23, 21, 'moshe571', 'rapaport571', '709429', 21, 'B', 'BUSINESS'),
(598, 23, 1, 'moshe572', 'rapaport572', '719428', 22, 'C', 'ECONOMY'),
(599, 16, 34, 'moshe573', 'rapaport573', '729427', 23, 'D', 'FIRST'),
(600, 8, 26, 'moshe574', 'rapaport574', '739426', 24, 'E', 'BUSINESS'),
(601, 2, 24, 'moshe575', 'rapaport575', '749425', 25, 'F', 'ECONOMY'),
(602, 19, 21, 'moshe576', 'rapaport576', '759424', 26, 'A', 'FIRST'),
(603, 3, 11, 'moshe577', 'rapaport577', '769423', 27, 'B', 'BUSINESS'),
(604, 19, 30, 'moshe578', 'rapaport578', '779422', 28, 'C', 'ECONOMY'),
(605, 17, 35, 'moshe579', 'rapaport579', '789421', 29, 'D', 'FIRST'),
(606, 24, 30, 'moshe580', 'rapaport580', '799420', 30, 'E', 'BUSINESS'),
(607, 17, 10, 'moshe581', 'rapaport581', '809419', 31, 'F', 'ECONOMY'),
(608, 21, 24, 'moshe582', 'rapaport582', '819418', 32, 'A', 'FIRST'),
(609, 22, 2, 'moshe583', 'rapaport583', '829417', 33, 'B', 'BUSINESS'),
(610, 13, 18, 'moshe584', 'rapaport584', '839416', 34, 'C', 'ECONOMY'),
(611, 16, 32, 'moshe585', 'rapaport585', '849415', 35, 'D', 'FIRST'),
(612, 13, 24, 'moshe586', 'rapaport586', '859414', 36, 'E', 'BUSINESS'),
(613, 16, 16, 'moshe587', 'rapaport587', '869413', 37, 'F', 'ECONOMY'),
(614, 7, 10, 'moshe588', 'rapaport588', '879412', 38, 'A', 'FIRST'),
(615, 4, 26, 'moshe589', 'rapaport589', '889411', 39, 'B', 'BUSINESS'),
(616, 1, 30, 'moshe590', 'rapaport590', '899410', 40, 'C', 'ECONOMY'),
(617, 24, 26, 'moshe591', 'rapaport591', '909409', 41, 'D', 'FIRST'),
(618, 21, 4, 'moshe592', 'rapaport592', '919408', 42, 'E', 'BUSINESS'),
(619, 14, 25, 'moshe593', 'rapaport593', '929407', 43, 'F', 'ECONOMY'),
(620, 21, 17, 'moshe594', 'rapaport594', '939406', 44, 'A', 'FIRST'),
(621, 23, 21, 'moshe595', 'rapaport595', '949405', 45, 'B', 'BUSINESS'),
(622, 20, 32, 'moshe596', 'rapaport596', '959404', 46, 'C', 'ECONOMY'),
(623, 18, 5, 'moshe597', 'rapaport597', '969403', 47, 'D', 'FIRST'),
(624, 19, 18, 'moshe598', 'rapaport598', '979402', 48, 'E', 'BUSINESS'),
(625, 15, 19, 'moshe599', 'rapaport599', '989401', 49, 'F', 'ECONOMY'),
(626, 16, 1, 'moshe600', 'rapaport600', '999400', 0, 'A', 'FIRST'),
(627, 7, 29, 'moshe601', 'rapaport601', '9399', 1, 'B', 'BUSINESS'),
(628, 9, 24, 'moshe602', 'rapaport602', '19398', 2, 'C', 'ECONOMY'),
(629, 18, 30, 'moshe603', 'rapaport603', '29397', 3, 'D', 'FIRST'),
(630, 9, 11, 'moshe604', 'rapaport604', '39396', 4, 'E', 'BUSINESS'),
(631, 19, 30, 'moshe605', 'rapaport605', '49395', 5, 'F', 'ECONOMY'),
(632, 14, 30, 'moshe606', 'rapaport606', '59394', 6, 'A', 'FIRST'),
(633, 21, 21, 'moshe607', 'rapaport607', '69393', 7, 'B', 'BUSINESS'),
(634, 15, 11, 'moshe608', 'rapaport608', '79392', 8, 'C', 'ECONOMY'),
(635, 10, 6, 'moshe609', 'rapaport609', '89391', 9, 'D', 'FIRST'),
(636, 25, 37, 'moshe610', 'rapaport610', '99390', 10, 'E', 'BUSINESS'),
(637, 25, 27, 'moshe611', 'rapaport611', '109389', 11, 'F', 'ECONOMY'),
(638, 23, 27, 'moshe612', 'rapaport612', '119388', 12, 'A', 'FIRST'),
(639, 9, 35, 'moshe613', 'rapaport613', '129387', 13, 'B', 'BUSINESS'),
(640, 23, 11, 'moshe614', 'rapaport614', '139386', 14, 'C', 'ECONOMY'),
(641, 24, 10, 'moshe615', 'rapaport615', '149385', 15, 'D', 'FIRST'),
(642, 17, 24, 'moshe616', 'rapaport616', '159384', 16, 'E', 'BUSINESS'),
(643, 15, 11, 'moshe617', 'rapaport617', '169383', 17, 'F', 'ECONOMY'),
(644, 8, 25, 'moshe618', 'rapaport618', '179382', 18, 'A', 'FIRST'),
(645, 4, 11, 'moshe619', 'rapaport619', '189381', 19, 'B', 'BUSINESS'),
(646, 15, 36, 'moshe620', 'rapaport620', '199380', 20, 'C', 'ECONOMY'),
(647, 4, 21, 'moshe621', 'rapaport621', '209379', 21, 'D', 'FIRST'),
(648, 18, 3, 'moshe622', 'rapaport622', '219378', 22, 'E', 'BUSINESS'),
(649, 3, 11, 'moshe623', 'rapaport623', '229377', 23, 'F', 'ECONOMY'),
(650, 9, 31, 'moshe624', 'rapaport624', '239376', 24, 'A', 'FIRST'),
(651, 12, 36, 'moshe625', 'rapaport625', '249375', 25, 'B', 'BUSINESS'),
(652, 1, 11, 'moshe626', 'rapaport626', '259374', 26, 'C', 'ECONOMY'),
(653, 20, 27, 'moshe627', 'rapaport627', '269373', 27, 'D', 'FIRST'),
(654, 7, 25, 'moshe628', 'rapaport628', '279372', 28, 'E', 'BUSINESS'),
(655, 7, 27, 'moshe629', 'rapaport629', '289371', 29, 'F', 'ECONOMY'),
(656, 20, 25, 'moshe630', 'rapaport630', '299370', 30, 'A', 'FIRST'),
(657, 5, 21, 'moshe631', 'rapaport631', '309369', 31, 'B', 'BUSINESS'),
(658, 12, 29, 'moshe632', 'rapaport632', '319368', 32, 'C', 'ECONOMY'),
(659, 21, 24, 'moshe633', 'rapaport633', '329367', 33, 'D', 'FIRST'),
(660, 17, 31, 'moshe634', 'rapaport634', '339366', 34, 'E', 'BUSINESS'),
(661, 6, 34, 'moshe635', 'rapaport635', '349365', 35, 'F', 'ECONOMY'),
(662, 7, 26, 'moshe636', 'rapaport636', '359364', 36, 'A', 'FIRST'),
(663, 18, 4, 'moshe637', 'rapaport637', '369363', 37, 'B', 'BUSINESS'),
(664, 2, 2, 'moshe638', 'rapaport638', '379362', 38, 'C', 'ECONOMY'),
(665, 12, 29, 'moshe639', 'rapaport639', '389361', 39, 'D', 'FIRST'),
(666, 15, 25, 'moshe640', 'rapaport640', '399360', 40, 'E', 'BUSINESS'),
(667, 6, 32, 'moshe641', 'rapaport641', '409359', 41, 'F', 'ECONOMY'),
(668, 10, 37, 'moshe642', 'rapaport642', '419358', 42, 'A', 'FIRST'),
(669, 7, 25, 'moshe643', 'rapaport643', '429357', 43, 'B', 'BUSINESS'),
(670, 1, 30, 'moshe644', 'rapaport644', '439356', 44, 'C', 'ECONOMY'),
(671, 4, 24, 'moshe645', 'rapaport645', '449355', 45, 'D', 'FIRST'),
(672, 10, 11, 'moshe646', 'rapaport646', '459354', 46, 'E', 'BUSINESS'),
(673, 15, 26, 'moshe647', 'rapaport647', '469353', 47, 'F', 'ECONOMY'),
(674, 16, 10, 'moshe648', 'rapaport648', '479352', 48, 'A', 'FIRST'),
(675, 13, 35, 'moshe649', 'rapaport649', '489351', 49, 'B', 'BUSINESS'),
(676, 25, 5, 'moshe650', 'rapaport650', '499350', 0, 'C', 'ECONOMY'),
(677, 25, 6, 'moshe651', 'rapaport651', '509349', 1, 'D', 'FIRST'),
(678, 11, 10, 'moshe652', 'rapaport652', '519348', 2, 'E', 'BUSINESS'),
(679, 8, 35, 'moshe653', 'rapaport653', '529347', 3, 'F', 'ECONOMY'),
(680, 14, 34, 'moshe654', 'rapaport654', '539346', 4, 'A', 'FIRST'),
(681, 1, 27, 'moshe655', 'rapaport655', '549345', 5, 'B', 'BUSINESS'),
(682, 21, 31, 'moshe656', 'rapaport656', '559344', 6, 'C', 'ECONOMY'),
(683, 23, 29, 'moshe657', 'rapaport657', '569343', 7, 'D', 'FIRST'),
(684, 1, 21, 'moshe658', 'rapaport658', '579342', 8, 'E', 'BUSINESS'),
(685, 9, 27, 'moshe659', 'rapaport659', '589341', 9, 'F', 'ECONOMY'),
(686, 14, 34, 'moshe660', 'rapaport660', '599340', 10, 'A', 'FIRST'),
(687, 23, 17, 'moshe661', 'rapaport661', '609339', 11, 'B', 'BUSINESS'),
(688, 5, 36, 'moshe662', 'rapaport662', '619338', 12, 'C', 'ECONOMY'),
(689, 4, 21, 'moshe663', 'rapaport663', '629337', 13, 'D', 'FIRST'),
(690, 5, 25, 'moshe664', 'rapaport664', '639336', 14, 'E', 'BUSINESS'),
(691, 3, 29, 'moshe665', 'rapaport665', '649335', 15, 'F', 'ECONOMY'),
(692, 3, 10, 'moshe666', 'rapaport666', '659334', 16, 'A', 'FIRST'),
(693, 23, 3, 'moshe667', 'rapaport667', '669333', 17, 'B', 'BUSINESS'),
(694, 5, 21, 'moshe668', 'rapaport668', '679332', 18, 'C', 'ECONOMY'),
(695, 9, 5, 'moshe669', 'rapaport669', '689331', 19, 'D', 'FIRST'),
(696, 8, 26, 'moshe670', 'rapaport670', '699330', 20, 'E', 'BUSINESS'),
(697, 25, 37, 'moshe671', 'rapaport671', '709329', 21, 'F', 'ECONOMY'),
(698, 9, 26, 'moshe672', 'rapaport672', '719328', 22, 'A', 'FIRST'),
(699, 8, 4, 'moshe673', 'rapaport673', '729327', 23, 'B', 'BUSINESS'),
(700, 21, 32, 'moshe674', 'rapaport674', '739326', 24, 'C', 'ECONOMY'),
(701, 12, 21, 'moshe675', 'rapaport675', '749325', 25, 'D', 'FIRST'),
(702, 8, 4, 'moshe676', 'rapaport676', '759324', 26, 'E', 'BUSINESS'),
(703, 19, 37, 'moshe677', 'rapaport677', '769323', 27, 'F', 'ECONOMY'),
(704, 4, 36, 'moshe678', 'rapaport678', '779322', 28, 'A', 'FIRST'),
(705, 24, 35, 'moshe679', 'rapaport679', '789321', 29, 'B', 'BUSINESS'),
(706, 7, 29, 'moshe680', 'rapaport680', '799320', 30, 'C', 'ECONOMY'),
(707, 14, 17, 'moshe681', 'rapaport681', '809319', 31, 'D', 'FIRST'),
(708, 22, 21, 'moshe682', 'rapaport682', '819318', 32, 'E', 'BUSINESS'),
(709, 13, 31, 'moshe683', 'rapaport683', '829317', 33, 'F', 'ECONOMY'),
(710, 7, 11, 'moshe684', 'rapaport684', '839316', 34, 'A', 'FIRST'),
(711, 15, 19, 'moshe685', 'rapaport685', '849315', 35, 'B', 'BUSINESS'),
(712, 22, 35, 'moshe686', 'rapaport686', '859314', 36, 'C', 'ECONOMY'),
(713, 14, 29, 'moshe687', 'rapaport687', '869313', 37, 'D', 'FIRST'),
(714, 8, 34, 'moshe688', 'rapaport688', '879312', 38, 'E', 'BUSINESS'),
(715, 2, 36, 'moshe689', 'rapaport689', '889311', 39, 'F', 'ECONOMY'),
(716, 22, 4, 'moshe690', 'rapaport690', '899310', 40, 'A', 'FIRST'),
(717, 21, 10, 'moshe691', 'rapaport691', '909309', 41, 'B', 'BUSINESS'),
(718, 21, 34, 'moshe692', 'rapaport692', '919308', 42, 'C', 'ECONOMY'),
(719, 25, 11, 'moshe693', 'rapaport693', '929307', 43, 'D', 'FIRST'),
(720, 21, 19, 'moshe694', 'rapaport694', '939306', 44, 'E', 'BUSINESS'),
(721, 14, 11, 'moshe695', 'rapaport695', '949305', 45, 'F', 'ECONOMY'),
(722, 2, 1, 'moshe696', 'rapaport696', '959304', 46, 'A', 'FIRST'),
(723, 14, 17, 'moshe697', 'rapaport697', '969303', 47, 'B', 'BUSINESS'),
(724, 24, 19, 'moshe698', 'rapaport698', '979302', 48, 'C', 'ECONOMY'),
(725, 3, 35, 'moshe699', 'rapaport699', '989301', 49, 'D', 'FIRST'),
(726, 12, 3, 'moshe700', 'rapaport700', '999300', 0, 'E', 'BUSINESS'),
(727, 24, 27, 'moshe701', 'rapaport701', '9299', 1, 'F', 'ECONOMY'),
(728, 8, 18, 'moshe702', 'rapaport702', '19298', 2, 'A', 'FIRST'),
(729, 6, 10, 'moshe703', 'rapaport703', '29297', 3, 'B', 'BUSINESS'),
(730, 7, 24, 'moshe704', 'rapaport704', '39296', 4, 'C', 'ECONOMY'),
(731, 20, 35, 'moshe705', 'rapaport705', '49295', 5, 'D', 'FIRST'),
(732, 10, 11, 'moshe706', 'rapaport706', '59294', 6, 'E', 'BUSINESS'),
(733, 19, 30, 'moshe707', 'rapaport707', '69293', 7, 'F', 'ECONOMY');
INSERT INTO `tickets` (`tickets_id`, `orders_id`, `flights_id`, `first_name_passenger`, `last_name_passenger`, `id_passenger`, `line`, `chair`, `department`) VALUES
(734, 20, 3, 'moshe708', 'rapaport708', '79292', 8, 'A', 'FIRST'),
(735, 25, 27, 'moshe709', 'rapaport709', '89291', 9, 'B', 'BUSINESS'),
(736, 5, 10, 'moshe710', 'rapaport710', '99290', 10, 'C', 'ECONOMY'),
(737, 8, 21, 'moshe711', 'rapaport711', '109289', 11, 'D', 'FIRST'),
(738, 13, 2, 'moshe712', 'rapaport712', '119288', 12, 'E', 'BUSINESS'),
(739, 18, 6, 'moshe713', 'rapaport713', '129287', 13, 'F', 'ECONOMY'),
(740, 2, 21, 'moshe714', 'rapaport714', '139286', 14, 'A', 'FIRST'),
(741, 11, 26, 'moshe715', 'rapaport715', '149285', 15, 'B', 'BUSINESS'),
(742, 6, 37, 'moshe716', 'rapaport716', '159284', 16, 'C', 'ECONOMY'),
(743, 24, 27, 'moshe717', 'rapaport717', '169283', 17, 'D', 'FIRST'),
(744, 13, 21, 'moshe718', 'rapaport718', '179282', 18, 'E', 'BUSINESS'),
(745, 3, 21, 'moshe719', 'rapaport719', '189281', 19, 'F', 'ECONOMY'),
(746, 3, 29, 'moshe720', 'rapaport720', '199280', 20, 'A', 'FIRST'),
(747, 5, 29, 'moshe721', 'rapaport721', '209279', 21, 'B', 'BUSINESS'),
(748, 22, 18, 'moshe722', 'rapaport722', '219278', 22, 'C', 'ECONOMY'),
(749, 19, 1, 'moshe723', 'rapaport723', '229277', 23, 'D', 'FIRST'),
(750, 16, 16, 'moshe724', 'rapaport724', '239276', 24, 'E', 'BUSINESS'),
(751, 9, 27, 'moshe725', 'rapaport725', '249275', 25, 'F', 'ECONOMY'),
(752, 14, 10, 'moshe726', 'rapaport726', '259274', 26, 'A', 'FIRST'),
(753, 11, 10, 'moshe727', 'rapaport727', '269273', 27, 'B', 'BUSINESS'),
(754, 8, 25, 'moshe728', 'rapaport728', '279272', 28, 'C', 'ECONOMY'),
(755, 17, 34, 'moshe729', 'rapaport729', '289271', 29, 'D', 'FIRST'),
(756, 19, 10, 'moshe730', 'rapaport730', '299270', 30, 'E', 'BUSINESS'),
(757, 8, 36, 'moshe731', 'rapaport731', '309269', 31, 'F', 'ECONOMY'),
(758, 7, 5, 'moshe732', 'rapaport732', '319268', 32, 'A', 'FIRST'),
(759, 22, 26, 'moshe733', 'rapaport733', '329267', 33, 'B', 'BUSINESS'),
(760, 15, 36, 'moshe734', 'rapaport734', '339266', 34, 'C', 'ECONOMY'),
(761, 1, 10, 'moshe735', 'rapaport735', '349265', 35, 'D', 'FIRST'),
(762, 20, 10, 'moshe736', 'rapaport736', '359264', 36, 'E', 'BUSINESS'),
(763, 24, 17, 'moshe737', 'rapaport737', '369263', 37, 'F', 'ECONOMY'),
(764, 9, 25, 'moshe738', 'rapaport738', '379262', 38, 'A', 'FIRST'),
(765, 21, 21, 'moshe739', 'rapaport739', '389261', 39, 'B', 'BUSINESS'),
(766, 13, 16, 'moshe740', 'rapaport740', '399260', 40, 'C', 'ECONOMY'),
(767, 23, 21, 'moshe741', 'rapaport741', '409259', 41, 'D', 'FIRST'),
(768, 25, 32, 'moshe742', 'rapaport742', '419258', 42, 'E', 'BUSINESS'),
(769, 9, 3, 'moshe743', 'rapaport743', '429257', 43, 'F', 'ECONOMY'),
(770, 24, 32, 'moshe744', 'rapaport744', '439256', 44, 'A', 'FIRST'),
(771, 15, 35, 'moshe745', 'rapaport745', '449255', 45, 'B', 'BUSINESS'),
(772, 2, 11, 'moshe746', 'rapaport746', '459254', 46, 'C', 'ECONOMY'),
(773, 17, 4, 'moshe747', 'rapaport747', '469253', 47, 'D', 'FIRST'),
(774, 5, 10, 'moshe748', 'rapaport748', '479252', 48, 'E', 'BUSINESS'),
(775, 16, 16, 'moshe749', 'rapaport749', '489251', 49, 'F', 'ECONOMY'),
(776, 7, 26, 'moshe750', 'rapaport750', '499250', 0, 'A', 'FIRST'),
(777, 12, 10, 'moshe751', 'rapaport751', '509249', 1, 'B', 'BUSINESS'),
(778, 9, 21, 'moshe752', 'rapaport752', '519248', 2, 'C', 'ECONOMY'),
(779, 1, 21, 'moshe753', 'rapaport753', '529247', 3, 'D', 'FIRST'),
(780, 11, 21, 'moshe754', 'rapaport754', '539246', 4, 'E', 'BUSINESS'),
(781, 12, 24, 'moshe755', 'rapaport755', '549245', 5, 'F', 'ECONOMY'),
(782, 15, 11, 'moshe756', 'rapaport756', '559244', 6, 'A', 'FIRST'),
(783, 2, 4, 'moshe757', 'rapaport757', '569243', 7, 'B', 'BUSINESS'),
(784, 6, 19, 'moshe758', 'rapaport758', '579242', 8, 'C', 'ECONOMY'),
(785, 23, 10, 'moshe759', 'rapaport759', '589241', 9, 'D', 'FIRST'),
(786, 5, 21, 'moshe760', 'rapaport760', '599240', 10, 'E', 'BUSINESS'),
(787, 8, 27, 'moshe761', 'rapaport761', '609239', 11, 'F', 'ECONOMY'),
(788, 19, 36, 'moshe762', 'rapaport762', '619238', 12, 'A', 'FIRST'),
(789, 7, 10, 'moshe763', 'rapaport763', '629237', 13, 'B', 'BUSINESS'),
(790, 18, 21, 'moshe764', 'rapaport764', '639236', 14, 'C', 'ECONOMY'),
(791, 16, 11, 'moshe765', 'rapaport765', '649235', 15, 'D', 'FIRST'),
(792, 3, 21, 'moshe766', 'rapaport766', '659234', 16, 'E', 'BUSINESS'),
(793, 9, 21, 'moshe767', 'rapaport767', '669233', 17, 'F', 'ECONOMY'),
(794, 21, 18, 'moshe768', 'rapaport768', '679232', 18, 'A', 'FIRST'),
(795, 3, 21, 'moshe769', 'rapaport769', '689231', 19, 'B', 'BUSINESS'),
(796, 5, 11, 'moshe770', 'rapaport770', '699230', 20, 'C', 'ECONOMY'),
(797, 10, 2, 'moshe771', 'rapaport771', '709229', 21, 'D', 'FIRST'),
(798, 4, 26, 'moshe772', 'rapaport772', '719228', 22, 'E', 'BUSINESS'),
(799, 14, 3, 'moshe773', 'rapaport773', '729227', 23, 'F', 'ECONOMY'),
(800, 12, 5, 'moshe774', 'rapaport774', '739226', 24, 'A', 'FIRST'),
(801, 18, 34, 'moshe775', 'rapaport775', '749225', 25, 'B', 'BUSINESS'),
(802, 12, 21, 'moshe776', 'rapaport776', '759224', 26, 'C', 'ECONOMY'),
(803, 10, 16, 'moshe777', 'rapaport777', '769223', 27, 'D', 'FIRST'),
(804, 11, 30, 'moshe778', 'rapaport778', '779222', 28, 'E', 'BUSINESS'),
(805, 15, 24, 'moshe779', 'rapaport779', '789221', 29, 'F', 'ECONOMY'),
(806, 17, 21, 'moshe780', 'rapaport780', '799220', 30, 'A', 'FIRST'),
(807, 25, 32, 'moshe781', 'rapaport781', '809219', 31, 'B', 'BUSINESS'),
(808, 10, 3, 'moshe782', 'rapaport782', '819218', 32, 'C', 'ECONOMY'),
(809, 25, 21, 'moshe783', 'rapaport783', '829217', 33, 'D', 'FIRST'),
(810, 1, 17, 'moshe784', 'rapaport784', '839216', 34, 'E', 'BUSINESS'),
(811, 10, 30, 'moshe785', 'rapaport785', '849215', 35, 'F', 'ECONOMY'),
(812, 5, 24, 'moshe786', 'rapaport786', '859214', 36, 'A', 'FIRST'),
(813, 20, 18, 'moshe787', 'rapaport787', '869213', 37, 'B', 'BUSINESS'),
(814, 7, 6, 'moshe788', 'rapaport788', '879212', 38, 'C', 'ECONOMY'),
(815, 20, 21, 'moshe789', 'rapaport789', '889211', 39, 'D', 'FIRST'),
(816, 1, 21, 'moshe790', 'rapaport790', '899210', 40, 'E', 'BUSINESS'),
(817, 20, 10, 'moshe791', 'rapaport791', '909209', 41, 'F', 'ECONOMY'),
(818, 15, 34, 'moshe792', 'rapaport792', '919208', 42, 'A', 'FIRST'),
(819, 9, 31, 'moshe793', 'rapaport793', '929207', 43, 'B', 'BUSINESS'),
(820, 18, 32, 'moshe794', 'rapaport794', '939206', 44, 'C', 'ECONOMY'),
(821, 9, 21, 'moshe795', 'rapaport795', '949205', 45, 'D', 'FIRST'),
(822, 23, 10, 'moshe796', 'rapaport796', '959204', 46, 'E', 'BUSINESS'),
(823, 1, 4, 'moshe797', 'rapaport797', '969203', 47, 'F', 'ECONOMY'),
(824, 12, 21, 'moshe798', 'rapaport798', '979202', 48, 'A', 'FIRST'),
(825, 8, 19, 'moshe799', 'rapaport799', '989201', 49, 'B', 'BUSINESS'),
(826, 15, 16, 'moshe800', 'rapaport800', '999200', 0, 'C', 'ECONOMY'),
(827, 10, 25, 'moshe801', 'rapaport801', '9199', 1, 'D', 'FIRST'),
(828, 17, 10, 'moshe802', 'rapaport802', '19198', 2, 'E', 'BUSINESS'),
(829, 16, 32, 'moshe803', 'rapaport803', '29197', 3, 'F', 'ECONOMY'),
(830, 19, 24, 'moshe804', 'rapaport804', '39196', 4, 'A', 'FIRST'),
(831, 15, 25, 'moshe805', 'rapaport805', '49195', 5, 'B', 'BUSINESS'),
(832, 22, 27, 'moshe806', 'rapaport806', '59194', 6, 'C', 'ECONOMY'),
(833, 10, 37, 'moshe807', 'rapaport807', '69193', 7, 'D', 'FIRST'),
(834, 12, 11, 'moshe808', 'rapaport808', '79192', 8, 'E', 'BUSINESS'),
(835, 20, 37, 'moshe809', 'rapaport809', '89191', 9, 'F', 'ECONOMY'),
(836, 5, 11, 'moshe810', 'rapaport810', '99190', 10, 'A', 'FIRST'),
(837, 11, 29, 'moshe811', 'rapaport811', '109189', 11, 'B', 'BUSINESS'),
(838, 3, 16, 'moshe812', 'rapaport812', '119188', 12, 'C', 'ECONOMY'),
(839, 21, 30, 'moshe813', 'rapaport813', '129187', 13, 'D', 'FIRST'),
(840, 8, 30, 'moshe814', 'rapaport814', '139186', 14, 'E', 'BUSINESS'),
(841, 14, 32, 'moshe815', 'rapaport815', '149185', 15, 'F', 'ECONOMY'),
(842, 12, 17, 'moshe816', 'rapaport816', '159184', 16, 'A', 'FIRST'),
(843, 1, 10, 'moshe817', 'rapaport817', '169183', 17, 'B', 'BUSINESS'),
(844, 6, 11, 'moshe818', 'rapaport818', '179182', 18, 'C', 'ECONOMY'),
(845, 21, 16, 'moshe819', 'rapaport819', '189181', 19, 'D', 'FIRST'),
(846, 18, 17, 'moshe820', 'rapaport820', '199180', 20, 'E', 'BUSINESS'),
(847, 22, 11, 'moshe821', 'rapaport821', '209179', 21, 'F', 'ECONOMY'),
(848, 11, 1, 'moshe822', 'rapaport822', '219178', 22, 'A', 'FIRST'),
(849, 18, 1, 'moshe823', 'rapaport823', '229177', 23, 'B', 'BUSINESS'),
(850, 14, 35, 'moshe824', 'rapaport824', '239176', 24, 'C', 'ECONOMY'),
(851, 11, 32, 'moshe825', 'rapaport825', '249175', 25, 'D', 'FIRST'),
(852, 10, 18, 'moshe826', 'rapaport826', '259174', 26, 'E', 'BUSINESS'),
(853, 10, 34, 'moshe827', 'rapaport827', '269173', 27, 'F', 'ECONOMY'),
(854, 15, 19, 'moshe828', 'rapaport828', '279172', 28, 'A', 'FIRST'),
(855, 7, 34, 'moshe829', 'rapaport829', '289171', 29, 'B', 'BUSINESS'),
(856, 22, 25, 'moshe830', 'rapaport830', '299170', 30, 'C', 'ECONOMY'),
(857, 10, 3, 'moshe831', 'rapaport831', '309169', 31, 'D', 'FIRST'),
(858, 18, 11, 'moshe832', 'rapaport832', '319168', 32, 'E', 'BUSINESS'),
(859, 7, 17, 'moshe833', 'rapaport833', '329167', 33, 'F', 'ECONOMY'),
(860, 15, 17, 'moshe834', 'rapaport834', '339166', 34, 'A', 'FIRST'),
(861, 14, 32, 'moshe835', 'rapaport835', '349165', 35, 'B', 'BUSINESS'),
(862, 13, 21, 'moshe836', 'rapaport836', '359164', 36, 'C', 'ECONOMY'),
(863, 15, 30, 'moshe837', 'rapaport837', '369163', 37, 'D', 'FIRST'),
(864, 12, 21, 'moshe838', 'rapaport838', '379162', 38, 'E', 'BUSINESS'),
(865, 22, 26, 'moshe839', 'rapaport839', '389161', 39, 'F', 'ECONOMY'),
(866, 13, 21, 'moshe840', 'rapaport840', '399160', 40, 'A', 'FIRST'),
(867, 16, 11, 'moshe841', 'rapaport841', '409159', 41, 'B', 'BUSINESS'),
(868, 3, 31, 'moshe842', 'rapaport842', '419158', 42, 'C', 'ECONOMY'),
(869, 6, 16, 'moshe843', 'rapaport843', '429157', 43, 'D', 'FIRST'),
(870, 19, 10, 'moshe844', 'rapaport844', '439156', 44, 'E', 'BUSINESS'),
(871, 22, 25, 'moshe845', 'rapaport845', '449155', 45, 'F', 'ECONOMY'),
(872, 1, 32, 'moshe846', 'rapaport846', '459154', 46, 'A', 'FIRST'),
(873, 5, 6, 'moshe847', 'rapaport847', '469153', 47, 'B', 'BUSINESS'),
(874, 6, 31, 'moshe848', 'rapaport848', '479152', 48, 'C', 'ECONOMY'),
(875, 3, 35, 'moshe849', 'rapaport849', '489151', 49, 'D', 'FIRST'),
(876, 17, 30, 'moshe850', 'rapaport850', '499150', 0, 'E', 'BUSINESS'),
(877, 1, 29, 'moshe851', 'rapaport851', '509149', 1, 'F', 'ECONOMY'),
(878, 8, 37, 'moshe852', 'rapaport852', '519148', 2, 'A', 'FIRST'),
(879, 14, 31, 'moshe853', 'rapaport853', '529147', 3, 'B', 'BUSINESS'),
(880, 21, 29, 'moshe854', 'rapaport854', '539146', 4, 'C', 'ECONOMY'),
(881, 19, 18, 'moshe855', 'rapaport855', '549145', 5, 'D', 'FIRST'),
(882, 6, 36, 'moshe856', 'rapaport856', '559144', 6, 'E', 'BUSINESS'),
(883, 1, 10, 'moshe857', 'rapaport857', '569143', 7, 'F', 'ECONOMY'),
(884, 4, 31, 'moshe858', 'rapaport858', '579142', 8, 'A', 'FIRST'),
(885, 19, 19, 'moshe859', 'rapaport859', '589141', 9, 'B', 'BUSINESS'),
(886, 2, 25, 'moshe860', 'rapaport860', '599140', 10, 'C', 'ECONOMY'),
(887, 14, 27, 'moshe861', 'rapaport861', '609139', 11, 'D', 'FIRST'),
(888, 4, 24, 'moshe862', 'rapaport862', '619138', 12, 'E', 'BUSINESS'),
(889, 7, 3, 'moshe863', 'rapaport863', '629137', 13, 'F', 'ECONOMY'),
(890, 13, 21, 'moshe864', 'rapaport864', '639136', 14, 'A', 'FIRST'),
(891, 20, 4, 'moshe865', 'rapaport865', '649135', 15, 'B', 'BUSINESS'),
(892, 13, 11, 'moshe866', 'rapaport866', '659134', 16, 'C', 'ECONOMY'),
(893, 18, 11, 'moshe867', 'rapaport867', '669133', 17, 'D', 'FIRST'),
(894, 22, 16, 'moshe868', 'rapaport868', '679132', 18, 'E', 'BUSINESS'),
(895, 6, 10, 'moshe869', 'rapaport869', '689131', 19, 'F', 'ECONOMY'),
(896, 8, 37, 'moshe870', 'rapaport870', '699130', 20, 'A', 'FIRST'),
(897, 15, 34, 'moshe871', 'rapaport871', '709129', 21, 'B', 'BUSINESS'),
(898, 5, 19, 'moshe872', 'rapaport872', '719128', 22, 'C', 'ECONOMY'),
(899, 21, 37, 'moshe873', 'rapaport873', '729127', 23, 'D', 'FIRST'),
(900, 5, 30, 'moshe874', 'rapaport874', '739126', 24, 'E', 'BUSINESS'),
(901, 19, 32, 'moshe875', 'rapaport875', '749125', 25, 'F', 'ECONOMY'),
(902, 22, 19, 'moshe876', 'rapaport876', '759124', 26, 'A', 'FIRST'),
(903, 6, 10, 'moshe877', 'rapaport877', '769123', 27, 'B', 'BUSINESS'),
(904, 17, 4, 'moshe878', 'rapaport878', '779122', 28, 'C', 'ECONOMY'),
(905, 10, 1, 'moshe879', 'rapaport879', '789121', 29, 'D', 'FIRST'),
(906, 14, 34, 'moshe880', 'rapaport880', '799120', 30, 'E', 'BUSINESS'),
(907, 1, 10, 'moshe881', 'rapaport881', '809119', 31, 'F', 'ECONOMY'),
(908, 10, 35, 'moshe882', 'rapaport882', '819118', 32, 'A', 'FIRST'),
(909, 17, 21, 'moshe883', 'rapaport883', '829117', 33, 'B', 'BUSINESS'),
(910, 6, 11, 'moshe884', 'rapaport884', '839116', 34, 'C', 'ECONOMY'),
(911, 2, 34, 'moshe885', 'rapaport885', '849115', 35, 'D', 'FIRST'),
(912, 25, 3, 'moshe886', 'rapaport886', '859114', 36, 'E', 'BUSINESS'),
(913, 17, 25, 'moshe887', 'rapaport887', '869113', 37, 'F', 'ECONOMY'),
(914, 14, 25, 'moshe888', 'rapaport888', '879112', 38, 'A', 'FIRST'),
(915, 25, 4, 'moshe889', 'rapaport889', '889111', 39, 'B', 'BUSINESS'),
(916, 23, 34, 'moshe890', 'rapaport890', '899110', 40, 'C', 'ECONOMY'),
(917, 10, 31, 'moshe891', 'rapaport891', '909109', 41, 'D', 'FIRST'),
(918, 20, 10, 'moshe892', 'rapaport892', '919108', 42, 'E', 'BUSINESS'),
(919, 22, 1, 'moshe893', 'rapaport893', '929107', 43, 'F', 'ECONOMY'),
(920, 13, 19, 'moshe894', 'rapaport894', '939106', 44, 'A', 'FIRST'),
(921, 19, 1, 'moshe895', 'rapaport895', '949105', 45, 'B', 'BUSINESS'),
(922, 15, 29, 'moshe896', 'rapaport896', '959104', 46, 'C', 'ECONOMY'),
(923, 17, 10, 'moshe897', 'rapaport897', '969103', 47, 'D', 'FIRST'),
(924, 14, 32, 'moshe898', 'rapaport898', '979102', 48, 'E', 'BUSINESS'),
(925, 23, 26, 'moshe899', 'rapaport899', '989101', 49, 'F', 'ECONOMY'),
(926, 14, 5, 'moshe900', 'rapaport900', '999100', 0, 'A', 'FIRST'),
(927, 17, 18, 'moshe901', 'rapaport901', '9099', 1, 'B', 'BUSINESS'),
(928, 25, 21, 'moshe902', 'rapaport902', '19098', 2, 'C', 'ECONOMY'),
(929, 18, 21, 'moshe903', 'rapaport903', '29097', 3, 'D', 'FIRST'),
(930, 22, 31, 'moshe904', 'rapaport904', '39096', 4, 'E', 'BUSINESS'),
(931, 15, 30, 'moshe905', 'rapaport905', '49095', 5, 'F', 'ECONOMY'),
(932, 15, 30, 'moshe906', 'rapaport906', '59094', 6, 'A', 'FIRST'),
(933, 22, 37, 'moshe907', 'rapaport907', '69093', 7, 'B', 'BUSINESS'),
(934, 21, 21, 'moshe908', 'rapaport908', '79092', 8, 'C', 'ECONOMY'),
(935, 18, 21, 'moshe909', 'rapaport909', '89091', 9, 'D', 'FIRST'),
(936, 10, 18, 'moshe910', 'rapaport910', '99090', 10, 'E', 'BUSINESS'),
(937, 20, 10, 'moshe911', 'rapaport911', '109089', 11, 'F', 'ECONOMY'),
(938, 22, 27, 'moshe912', 'rapaport912', '119088', 12, 'A', 'FIRST'),
(939, 16, 35, 'moshe913', 'rapaport913', '129087', 13, 'B', 'BUSINESS'),
(940, 7, 11, 'moshe914', 'rapaport914', '139086', 14, 'C', 'ECONOMY'),
(941, 12, 18, 'moshe915', 'rapaport915', '149085', 15, 'D', 'FIRST'),
(942, 13, 21, 'moshe916', 'rapaport916', '159084', 16, 'E', 'BUSINESS'),
(943, 12, 19, 'moshe917', 'rapaport917', '169083', 17, 'F', 'ECONOMY'),
(944, 4, 17, 'moshe918', 'rapaport918', '179082', 18, 'A', 'FIRST'),
(945, 8, 21, 'moshe919', 'rapaport919', '189081', 19, 'B', 'BUSINESS'),
(946, 22, 21, 'moshe920', 'rapaport920', '199080', 20, 'C', 'ECONOMY'),
(947, 17, 29, 'moshe921', 'rapaport921', '209079', 21, 'D', 'FIRST'),
(948, 5, 11, 'moshe922', 'rapaport922', '219078', 22, 'E', 'BUSINESS'),
(949, 6, 11, 'moshe923', 'rapaport923', '229077', 23, 'F', 'ECONOMY'),
(950, 4, 16, 'moshe924', 'rapaport924', '239076', 24, 'A', 'FIRST'),
(951, 9, 18, 'moshe925', 'rapaport925', '249075', 25, 'B', 'BUSINESS'),
(952, 11, 11, 'moshe926', 'rapaport926', '259074', 26, 'C', 'ECONOMY'),
(953, 15, 10, 'moshe927', 'rapaport927', '269073', 27, 'D', 'FIRST'),
(954, 1, 21, 'moshe928', 'rapaport928', '279072', 28, 'E', 'BUSINESS'),
(955, 13, 21, 'moshe929', 'rapaport929', '289071', 29, 'F', 'ECONOMY'),
(956, 13, 24, 'moshe930', 'rapaport930', '299070', 30, 'A', 'FIRST'),
(957, 24, 21, 'moshe931', 'rapaport931', '309069', 31, 'B', 'BUSINESS'),
(958, 4, 21, 'moshe932', 'rapaport932', '319068', 32, 'C', 'ECONOMY'),
(959, 17, 3, 'moshe933', 'rapaport933', '329067', 33, 'D', 'FIRST'),
(960, 6, 4, 'moshe934', 'rapaport934', '339066', 34, 'E', 'BUSINESS'),
(961, 7, 11, 'moshe935', 'rapaport935', '349065', 35, 'F', 'ECONOMY'),
(962, 22, 29, 'moshe936', 'rapaport936', '359064', 36, 'A', 'FIRST'),
(963, 4, 4, 'moshe937', 'rapaport937', '369063', 37, 'B', 'BUSINESS'),
(964, 22, 10, 'moshe938', 'rapaport938', '379062', 38, 'C', 'ECONOMY'),
(965, 3, 11, 'moshe939', 'rapaport939', '389061', 39, 'D', 'FIRST'),
(966, 13, 24, 'moshe940', 'rapaport940', '399060', 40, 'E', 'BUSINESS'),
(967, 24, 10, 'moshe941', 'rapaport941', '409059', 41, 'F', 'ECONOMY'),
(968, 4, 21, 'moshe942', 'rapaport942', '419058', 42, 'A', 'FIRST'),
(969, 9, 24, 'moshe943', 'rapaport943', '429057', 43, 'B', 'BUSINESS'),
(970, 22, 1, 'moshe944', 'rapaport944', '439056', 44, 'C', 'ECONOMY'),
(971, 23, 11, 'moshe945', 'rapaport945', '449055', 45, 'D', 'FIRST'),
(972, 21, 11, 'moshe946', 'rapaport946', '459054', 46, 'E', 'BUSINESS'),
(973, 12, 32, 'moshe947', 'rapaport947', '469053', 47, 'F', 'ECONOMY'),
(974, 4, 18, 'moshe948', 'rapaport948', '479052', 48, 'A', 'FIRST'),
(975, 8, 35, 'moshe949', 'rapaport949', '489051', 49, 'B', 'BUSINESS'),
(976, 15, 1, 'moshe950', 'rapaport950', '499050', 0, 'C', 'ECONOMY'),
(977, 8, 10, 'moshe951', 'rapaport951', '509049', 1, 'D', 'FIRST'),
(978, 7, 34, 'moshe952', 'rapaport952', '519048', 2, 'E', 'BUSINESS'),
(979, 11, 10, 'moshe953', 'rapaport953', '529047', 3, 'F', 'ECONOMY'),
(980, 2, 30, 'moshe954', 'rapaport954', '539046', 4, 'A', 'FIRST'),
(981, 17, 11, 'moshe955', 'rapaport955', '549045', 5, 'B', 'BUSINESS'),
(982, 23, 11, 'moshe956', 'rapaport956', '559044', 6, 'C', 'ECONOMY'),
(983, 9, 4, 'moshe957', 'rapaport957', '569043', 7, 'D', 'FIRST'),
(984, 6, 21, 'moshe958', 'rapaport958', '579042', 8, 'E', 'BUSINESS'),
(985, 11, 29, 'moshe959', 'rapaport959', '589041', 9, 'F', 'ECONOMY'),
(986, 6, 30, 'moshe960', 'rapaport960', '599040', 10, 'A', 'FIRST'),
(987, 2, 10, 'moshe961', 'rapaport961', '609039', 11, 'B', 'BUSINESS'),
(988, 6, 27, 'moshe962', 'rapaport962', '619038', 12, 'C', 'ECONOMY'),
(989, 25, 4, 'moshe963', 'rapaport963', '629037', 13, 'D', 'FIRST'),
(990, 6, 25, 'moshe964', 'rapaport964', '639036', 14, 'E', 'BUSINESS'),
(991, 1, 21, 'moshe965', 'rapaport965', '649035', 15, 'F', 'ECONOMY'),
(992, 21, 21, 'moshe966', 'rapaport966', '659034', 16, 'A', 'FIRST'),
(993, 16, 21, 'moshe967', 'rapaport967', '669033', 17, 'B', 'BUSINESS'),
(994, 10, 36, 'moshe968', 'rapaport968', '679032', 18, 'C', 'ECONOMY'),
(995, 12, 30, 'moshe969', 'rapaport969', '689031', 19, 'D', 'FIRST'),
(996, 23, 21, 'moshe970', 'rapaport970', '699030', 20, 'E', 'BUSINESS'),
(997, 4, 6, 'moshe971', 'rapaport971', '709029', 21, 'F', 'ECONOMY'),
(998, 9, 26, 'moshe972', 'rapaport972', '719028', 22, 'A', 'FIRST'),
(999, 9, 11, 'moshe973', 'rapaport973', '729027', 23, 'B', 'BUSINESS'),
(1000, 22, 16, 'moshe974', 'rapaport974', '739026', 24, 'C', 'ECONOMY'),
(1001, 23, 32, 'moshe975', 'rapaport975', '749025', 25, 'D', 'FIRST'),
(1002, 20, 21, 'moshe976', 'rapaport976', '759024', 26, 'E', 'BUSINESS'),
(1003, 12, 11, 'moshe977', 'rapaport977', '769023', 27, 'F', 'ECONOMY'),
(1004, 1, 3, 'moshe978', 'rapaport978', '779022', 28, 'A', 'FIRST'),
(1005, 2, 32, 'moshe979', 'rapaport979', '789021', 29, 'B', 'BUSINESS'),
(1006, 23, 21, 'moshe980', 'rapaport980', '799020', 30, 'C', 'ECONOMY'),
(1007, 16, 25, 'moshe981', 'rapaport981', '809019', 31, 'D', 'FIRST'),
(1008, 25, 29, 'moshe982', 'rapaport982', '819018', 32, 'E', 'BUSINESS'),
(1009, 23, 37, 'moshe983', 'rapaport983', '829017', 33, 'F', 'ECONOMY'),
(1010, 14, 6, 'moshe984', 'rapaport984', '839016', 34, 'A', 'FIRST'),
(1011, 6, 16, 'moshe985', 'rapaport985', '849015', 35, 'B', 'BUSINESS'),
(1012, 21, 30, 'moshe986', 'rapaport986', '859014', 36, 'C', 'ECONOMY'),
(1013, 2, 30, 'moshe987', 'rapaport987', '869013', 37, 'D', 'FIRST'),
(1014, 25, 29, 'moshe988', 'rapaport988', '879012', 38, 'E', 'BUSINESS'),
(1015, 3, 25, 'moshe989', 'rapaport989', '889011', 39, 'F', 'ECONOMY'),
(1016, 22, 30, 'moshe990', 'rapaport990', '899010', 40, 'A', 'FIRST'),
(1017, 21, 11, 'moshe991', 'rapaport991', '909009', 41, 'B', 'BUSINESS'),
(1018, 23, 21, 'moshe992', 'rapaport992', '919008', 42, 'C', 'ECONOMY'),
(1019, 24, 26, 'moshe993', 'rapaport993', '929007', 43, 'D', 'FIRST'),
(1020, 7, 21, 'moshe994', 'rapaport994', '939006', 44, 'E', 'BUSINESS'),
(1021, 13, 16, 'moshe995', 'rapaport995', '949005', 45, 'F', 'ECONOMY'),
(1022, 16, 17, 'moshe996', 'rapaport996', '959004', 46, 'A', 'FIRST'),
(1023, 3, 21, 'moshe997', 'rapaport997', '969003', 47, 'B', 'BUSINESS'),
(1024, 6, 24, 'moshe998', 'rapaport998', '979002', 48, 'C', 'ECONOMY'),
(1025, 15, 27, 'moshe999', 'rapaport999', '989001', 49, 'D', 'FIRST');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `airports`
--
ALTER TABLE `airports`
  ADD PRIMARY KEY (`airports_id`);

--
-- Indexes for table `club_members`
--
ALTER TABLE `club_members`
  ADD PRIMARY KEY (`club_members_id`);

--
-- Indexes for table `flights`
--
ALTER TABLE `flights`
  ADD PRIMARY KEY (`flights_id`),
  ADD KEY `planes_id` (`planes_id`),
  ADD KEY `pilots_id` (`pilots_id`),
  ADD KEY `origin` (`origin`),
  ADD KEY `target` (`target`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`orders_id`),
  ADD KEY `club_members_id` (`club_members_id`);

--
-- Indexes for table `pilots`
--
ALTER TABLE `pilots`
  ADD PRIMARY KEY (`pilots_id`);

--
-- Indexes for table `planes`
--
ALTER TABLE `planes`
  ADD PRIMARY KEY (`planes_id`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`tickets_id`),
  ADD KEY `orders_id` (`orders_id`),
  ADD KEY `flights_id` (`flights_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `airports`
--
ALTER TABLE `airports`
  MODIFY `airports_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `club_members`
--
ALTER TABLE `club_members`
  MODIFY `club_members_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `flights`
--
ALTER TABLE `flights`
  MODIFY `flights_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `orders_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `pilots`
--
ALTER TABLE `pilots`
  MODIFY `pilots_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `planes`
--
ALTER TABLE `planes`
  MODIFY `planes_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `tickets_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1026;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `flights`
--
ALTER TABLE `flights`
  ADD CONSTRAINT `flights_ibfk_1` FOREIGN KEY (`planes_id`) REFERENCES `planes` (`planes_id`),
  ADD CONSTRAINT `flights_ibfk_2` FOREIGN KEY (`pilots_id`) REFERENCES `pilots` (`pilots_id`),
  ADD CONSTRAINT `flights_ibfk_3` FOREIGN KEY (`origin`) REFERENCES `airports` (`airports_id`),
  ADD CONSTRAINT `flights_ibfk_4` FOREIGN KEY (`target`) REFERENCES `airports` (`airports_id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`club_members_id`) REFERENCES `club_members` (`club_members_id`);

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`orders_id`) REFERENCES `orders` (`orders_id`),
  ADD CONSTRAINT `tickets_ibfk_2` FOREIGN KEY (`flights_id`) REFERENCES `flights` (`flights_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
