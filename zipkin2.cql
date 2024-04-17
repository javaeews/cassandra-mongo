CREATE KEYSPACE IF NOT EXISTS zipkin2
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '2'}
  AND durable_writes = false;

CREATE TYPE IF NOT EXISTS zipkin2.endpoint (
    service      text,
    ipv4         inet,
    ipv6         inet,
    port         int,
);

CREATE TYPE IF NOT EXISTS zipkin2.annotation (
    ts bigint,
    v  text,
);

CREATE TABLE IF NOT EXISTS zipkin2.span (
    trace_id            text, // when strictTraceId=false, only contains right-most 16 chars
    ts_uuid             timeuuid,
    id                  text,
    trace_id_high       text, // when strictTraceId=false, contains left-most 16 chars if present
    parent_id           text,
    kind                text,
    span                text, // span.name
    ts                  bigint,
    duration            bigint,
    l_ep                Endpoint,
    r_ep                Endpoint,
    annotations         list<frozen<annotation>>,
    tags                map<text,text>,
    debug               boolean,
    shared              boolean,
    PRIMARY KEY (trace_id, ts_uuid, id)
)
    WITH CLUSTERING ORDER BY (ts_uuid DESC)
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.TimeWindowCompactionStrategy'}
    AND default_time_to_live =  604800
    AND gc_grace_seconds = 3600
    AND speculative_retry = '95percentile'
    AND comment = 'Primary table for holding trace data';

CREATE TABLE IF NOT EXISTS zipkin2.dependency (
    day          date,
    parent       text,
    child        text,
    errors       bigint,
    calls        bigint,
    PRIMARY KEY (day, parent, child)
)
    WITH compaction = {'class': 'org.apache.cassandra.db.compaction.LeveledCompactionStrategy', 'unchecked_tombstone_compaction': 'true', 'tombstone_threshold': '0.2'}
    AND default_time_to_live =  259200
    AND gc_grace_seconds = 3600
    AND comment = 'Holder for each days generation of zipkin2.DependencyLink';
	
	
	
	
	
	
	
	
	
	
ALTER TABLE zipkin2.span ADD l_service text;
DROP INDEX IF EXISTS zipkin2.span_l_service_idx;

CREATE TABLE IF NOT EXISTS zipkin2.trace_by_service_span (
    service       text,             //-- service name
    span          text,             //-- span name, or blank for queries without span name
    bucket        int,              //-- time bucket, calculated as ts/interval (in microseconds), for some pre-configured interval like 1 day.
    ts            timeuuid,         //-- start timestamp of the span, truncated to millisecond precision
    trace_id      text,             //-- trace ID
    duration      bigint,           //-- span duration, in milliseconds
    PRIMARY KEY ((service, span, bucket), ts)
)
   WITH CLUSTERING ORDER BY (ts DESC)
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.TimeWindowCompactionStrategy'}
    AND default_time_to_live =  259200
    AND gc_grace_seconds = 3600
    AND speculative_retry = '95percentile'
    AND comment = 'Secondary table for looking up a trace by a service, or service and span. span column may be blank (when only looking up by service). bucket column adds time bucketing to the partition key, values are microseconds rounded to a pre-configured interval (typically one day). ts column is start timestamp of the span as time-uuid, truncated to millisecond precision. duration column is span duration, rounded up to tens of milliseconds (or hundredths of seconds)';


CREATE TABLE IF NOT EXISTS zipkin2.trace_by_service_remote_service (
    service         text,             //-- service name
    remote_service  text,             //-- remote servie name
    bucket          int,              //-- time bucket, calculated as ts/interval (in microseconds), for some pre-configured interval like 1 day.
    ts              timeuuid,         //-- start timestamp of the span, truncated to millisecond precision
    trace_id        text,             //-- trace ID
    PRIMARY KEY ((service, remote_service, bucket), ts)
)
   WITH CLUSTERING ORDER BY (ts DESC)
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.TimeWindowCompactionStrategy'}
    AND default_time_to_live =  259200
    AND gc_grace_seconds = 3600
    AND speculative_retry = '95percentile'
    AND comment = 'Secondary table for looking up a trace by a remote service. bucket column adds time bucketing to the partition key, values are microseconds rounded to a pre-configured interval (typically one day). ts column is start timestamp of the span as time-uuid, truncated to millisecond precision.';

CREATE TABLE IF NOT EXISTS zipkin2.span_by_service (
    service text,
    span    text,
    PRIMARY KEY (service, span)
)
    WITH compaction = {'class': 'org.apache.cassandra.db.compaction.LeveledCompactionStrategy', 'unchecked_tombstone_compaction': 'true', 'tombstone_threshold': '0.2'}
    AND caching = {'rows_per_partition': 'ALL'}
    AND default_time_to_live =  259200
    AND gc_grace_seconds = 3600
    AND speculative_retry = '95percentile'
    AND comment = 'Secondary table for looking up span names by a service name. To compensate for hot partitions, we deduplicate write client side, use LeveledCompactionStrategy with a low threshold and add row caching.';

CREATE TABLE IF NOT EXISTS zipkin2.remote_service_by_service (
    service text,
    remote_service text,
    PRIMARY KEY (service, remote_service)
)
    WITH compaction = {'class': 'org.apache.cassandra.db.compaction.LeveledCompactionStrategy', 'unchecked_tombstone_compaction': 'true', 'tombstone_threshold': '0.2'}
    AND caching = {'rows_per_partition': 'ALL'}
    AND default_time_to_live =  259200
    AND gc_grace_seconds = 3600
    AND speculative_retry = '95percentile'
    AND comment = 'Secondary table for looking up remote service names by a service name. To compensate for hot partitions, we deduplicate write client side, use LeveledCompactionStrategy with a low threshold and add row caching.';

CREATE TABLE IF NOT EXISTS zipkin2.autocomplete_tags (
    key     text,
    value    text,
    PRIMARY KEY (key, value)
)
    WITH compaction = {'class': 'org.apache.cassandra.db.compaction.LeveledCompactionStrategy', 'unchecked_tombstone_compaction': 'true', 'tombstone_threshold': '0.2'}
    AND caching = {'rows_per_partition': 'ALL'}
    AND default_time_to_live =  259200
    AND gc_grace_seconds = 3600
    AND speculative_retry = '95percentile'
    AND comment = 'Secondary table for looking up span tag values for auto-complete purposes. To compensate for hot partitions, we deduplicate write client side, use LeveledCompactionStrategy with a low threshold and add row caching.';
	
	
	
	