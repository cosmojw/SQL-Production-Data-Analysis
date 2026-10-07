CREATE TABLE stations (
	station_id INTEGER PRIMARY KEY,
	name VARCHAR(50),
	target_cycle_time INTEGER
);

CREATE TABLE products (
	serial_number INTEGER PRIMARY KEY,
	model_name VARCHAR(50),
	status VARCHAR(50)
);

CREATE TABLE production_logs (
	log_id INTEGER PRIMARY KEY,
	serial_number INTEGER,
	station_id INTEGER,
	start_time INTEGER,
	finish_time INTEGER,
	FOREIGN KEY (serial_number)
	REFERENCES products(serial_number),
	FOREIGN KEY (station_id)
	REFERENCES stations(station_id)
);

INSERT INTO stations (name, target_cycle_time)
VALUES
('screen', 30),
('motherboard', 60),
('inspection', 45);

INSERT INTO products (model_name, status)
VALUES
('10 pro', 'in progress'),
('10 pro', 'completed'),
('11 lite', 'defective'),
('11 lite', 'in progress'),
('12 elite', 'completed');

INSERT INTO production_logs (serial_number, station_id, start_time, finish_time)
VALUES
(1, 1, 10, 45),
(1, 2, 50, 120),
(1, 3, 130, 175),
(2, 1, 5, 45),
(2, 2, 45, 105),
(2, 3, 110, 160),
(3, 1, 10, 45),
(3, 2, 50, 120),
(3, 3, 130, 175),
(4, 1, 15, 60),
(4, 2, 70, 130),
(4, 3, 135, 180),
(5, 1, 2, 35),
(5, 2, 45, 105),
(5, 3, 120, 165);

--Selects the serial number, station ID, cycle times, and target cycle times into one table
SELECT
	serial_number,
	production_logs.station_id,
	finish_time - start_time AS actual_cycle_time,
	target_cycle_time
FROM production_logs
INNER JOIN stations
ON stations.station_id = production_logs.station_id
WHERE finish_time - start_time > target_cycle_time

--Selects the sum of all of the wasted time (where cycle time is greater than target, sum up the differences)
SELECT
	SUM(finish_time - start_time - target_cycle_time) AS time_wasted
FROM production_logs
INNER JOIN stations
ON stations.station_id = production_logs.station_id
WHERE finish_time - start_time > target_cycle_time

--Selects the sum of wasted time by each station
SELECT
	production_logs.station_id,
	SUM(finish_time - start_time - target_cycle_time) AS time_wasted
FROM production_logs
INNER JOIN stations
ON stations.station_id = production_logs.station_id
WHERE finish_time - start_time > target_cycle_time
GROUP BY production_logs.station_id
HAVING time_wasted > 15
ORDER BY time_wasted DESC

--Selects station id from production logs table and determines if it is a bottleneck or on time (conditionals)
SELECT
	production_logs.station_id,
	CASE
		WHEN finish_time - start_time > target_cycle_time THEN 'Bottleneck'
		ELSE 'On Time'
	END AS time_status,
	COUNT(*) AS total_logs
FROM production_logs
INNER JOIN stations
ON stations.station_id = production_logs.station_id
GROUP BY production_logs.station_id, time_status

--Selects the number of bottlenecks and on time in each station using conditionals
SELECT
	production_logs.station_id,
	SUM(CASE
		WHEN finish_time - start_time > target_cycle_time THEN 1
		ELSE 0
	END) AS bottleneck_count,
	SUM(CASE
		WHEN finish_time - start_time <= target_cycle_time THEN 1
		ELSE 0
	END) AS ontime_count
FROM production_logs
INNER JOIN stations
ON stations.station_id = production_logs.station_id
GROUP BY production_logs.station_id

--Selects rows that have time cycles greater than the average time cycle using scalar subquery (nested SELECT)
SELECT *
FROM production_logs
WHERE finish_time - start_time >
	(SELECT
		AVG(finish_time - start_time)
	FROM production_logs)

--Selects rows that have time cycles greater than the average time cycle of their station using correlated subquery (linking outer log and inner log)
SELECT *
FROM production_logs outer_log
WHERE finish_time - start_time >
	(SELECT
		AVG(finish_time - start_time)
	FROM production_logs inner_log
	WHERE outer_log.station_id = inner_log.station_id)
	
--Selects the average counts from a table we made that gets all counts by station id (derived tables, subqueries in from)
SELECT
	AVG(total_logs) AS average_unit_count
FROM (
SELECT station_id, COUNT(*) AS total_logs
FROM production_logs
GROUP BY station_id
) AS station_counts

--Selects average counts using WITH instead of FROM nesting (CTEs)
WITH total_logs AS (
SELECT 
	station_id,
	COUNT(*) as log_count
FROM production_logs
GROUP BY station_id
)
SELECT
	AVG(log_count) as average_unit_count
FROM total_logs

--Selects station_id, how many logs are in each, and if it is greater than the average (using multiple WITH and CROSS JOIN)
WITH station_metrics AS (
	SELECT
		station_id,
		COUNT(*) AS log_count
	FROM production_logs
	GROUP BY station_id
),
plant_avg AS (
	SELECT
		AVG(log_count) AS average_log_count
	FROM station_metrics
)
SELECT
	station_id,
	log_count,
	CASE
		WHEN log_count > average_log_count THEN 'Yes'
		ELSE 'No'
	END AS log_count_greater_than_average
FROM station_metrics
CROSS JOIN plant_avg

