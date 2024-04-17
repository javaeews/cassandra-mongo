--UdtTimeSeries:
CREATE TYPE IF NOT EXISTS sensor_data_details (
                          data1 text,
                          data2 text,
                          data3 text
                        );
						
CREATE TABLE IF NOT EXISTS sensor_data_udt (
sensor_id text,
timestamp timeuuid,
data frozen<sensor_data_details>,
primary key(sensor_id, timestamp))
WITH CLUSTERING ORDER BY (timestamp DESC);


--Sets:      
CREATE TABLE IF NOT EXISTS sets (
key text primary key,
values set<text>
);

--SAI: 
CREATE TABLE IF NOT EXISTS sai (
    partition_id text,
    c_id int,
    value_text text,
    value_int int,
    primary key (partition_id, c_id)
);
CREATE INDEX IF NOT EXISTS ON sai (value_text) USING 'sai';
CREATE INDEX IF NOT EXISTS ON sai (value_int) USING 'sai';



--RandomPartitionAccess:
CREATE TABLE IF NOT EXISTS random_access (
partition_id text,
row_id int,
value text,
primary key (partition_id, row_id)
);

--Maps:         
CREATE TABLE IF NOT EXISTS map_stress (
id text, 
data map<text, text>, 
primary key (id)
); 


--DSESearch:
CREATE TABLE IF NOT EXISTS dse_search (
                    key text,
                    c int,
                    value_text text,
                    PRIMARY KEY (key, c)
            );
CREATE SEARCH INDEX IF NOT EXISTS ON dse_search WITH COLUMNS value_text;
 



--AllowFiltering:
CREATE TABLE IF NOT EXISTS allow_filtering (
partition_id text,
row_id int,
value int,
payload text,
primary key (partition_id, row_id)
); 
