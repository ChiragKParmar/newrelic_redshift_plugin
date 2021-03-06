module NewRelic::RedshiftPlugin

  # Register and run the agent
  def self.run
    # Register this agent.
    NewRelic::Plugin::Setup.install_agent :redshift, self

    # Launch the agent; this never returns.
    NewRelic::Plugin::Run.setup_and_run
  end


  class Agent < NewRelic::Plugin::Agent::Base

    agent_guid    'com.chirag.nr.redshift'
    agent_version NewRelic::RedshiftPlugin::VERSION
    agent_config_options :host, :port, :user, :password, :dbname, :label, :schema
    agent_human_labels('Redshift') { "#{label || host}" }

    def initialize(*args)
      @previous_metrics = {}
      @previous_result_for_query ||= {}
      super
    end

    #
    # Required, but not used
    #
    def setup_metrics
    end

    #
    # Picks up default port for redshift, if user doesn't specify port in yml file
    #
    def port
      @port || 5439
    end

    #
    # Get a connection to redshift
    #
    def connect
      PG::Connection.new(:host => host, :port => port, :user => user, :password => password, :dbname => dbname)
    end

    #
    # Following is called for every polling cycle
    #
    def poll_cycle
      @connection = self.connect
      puts 'Connected'
      report_metrics

    rescue => e
      $stderr.puts "#{e}: #{e.backtrace.join("\n  ")}"
    ensure
      @connection.finish if @connection
    end

    def report_metrics
      @connection.exec(percentage_memory_utilization) do |result|
        report_metric "Database/Memory/PercentageUtilized", '%' , result[0]['percentage_used']
      end

      @connection.exec(memory_used) do |result|
        report_metric "Database/Memory/Used", 'Gbytes' , result[0]['memory_used']
      end

      @connection.exec(maximum_capacity) do |result|
        report_metric "Database/Memory/MaxCapacity", 'Gbytes' , result[0]['capacity_gbytes']
      end

      @connection.exec(database_connections) do |result|
        report_metric "Database/Connections/NumberOfConnections", 'count' , result[0]['database_connections']
      end

      @connection.exec(total_rows_unsorted_rows_per_table).each do |result|
        report_metric "TableStats/TotalRows/#{result["table_name"]}", 'count' , result['total_rows']
      end

      @connection.exec(total_rows_unsorted_rows_per_table).each do |result|
        report_metric "TableStats/SortedRows/#{result["table_name"]}", 'count' , result['sorted_rows']
      end

      @connection.exec(total_rows_unsorted_rows_per_table).each do |result|
        report_metric "TableStats/UnsortedRows/#{result["table_name"]}", 'count' , result['unsorted_rows']
      end

      @connection.exec(total_rows_unsorted_rows_per_table).each do |result|
        report_metric "TableStats/UnsortedRatio/#{result["table_name"]}", '%' , result['unsorted_ratio']
      end

      #pct_of_total:  Size of the table in proportion to the cluster size
      @connection.exec(table_storage_information).each do |result|
        report_metric "TableStats/SizeInProportionToCluster/#{result["table_name"]}", '%' , result['pct_of_total']
      end
      
      #pct_stats_off:  Measure of staleness of table statistics (real size versus size recorded in stats)
      @connection.exec(table_storage_information).each do |result|
        report_metric "TableStats/SizeStaleness/#{result["table_name"]}", '%' , result['pct_stats_off']
      end

    end

    private

    def percentage_memory_utilization
          'SELECT ((SUM(used)/1024.00)*100)/((SUM(capacity))/1024)  AS percentage_used
          FROM    stv_partitions
          WHERE   part_begin=0;'
    end

    def memory_used
          'SELECT (SUM(used)/1024.00) AS memory_used
          FROM    stv_partitions
          WHERE   part_begin=0;'
    end 

    def maximum_capacity
          'SELECT  sum(capacity)/1024 AS capacity_gbytes
          FROM    stv_partitions
          WHERE   part_begin=0;'
    end     

    def database_connections
          'SELECT count(*) AS database_connections
           FROM stv_sessions;'
    end 

    def total_rows_unsorted_rows_per_table
      %Q{SELECT btrim(p.name::character varying::text) AS table_name, 
      sum(p."rows") AS total_rows, 
      sum(p.sorted_rows) AS sorted_rows, 
      sum(p."rows") - sum(p.sorted_rows) AS unsorted_rows,
      CASE WHEN sum(p."rows") <> 0 THEN 1.0::double precision - sum(p.sorted_rows)::double precision / sum(p."rows")::double precision
           ELSE NULL::double precision
           END AS unsorted_ratio
      FROM stv_tbl_perm p
      JOIN pg_database d ON d.oid = p.db_id::oid
      JOIN pg_class ON pg_class.oid = p.id::oid
      JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
      WHERE btrim(pg_namespace.nspname::character varying::text) = '#{schema}' AND p.id > 0
      GROUP BY btrim(pg_namespace.nspname::character varying::text), btrim(p.name::character varying::text)
      ORDER BY sum(p."rows") - sum(p.sorted_rows) DESC, sum(p.sorted_rows) DESC;}
    end

    def table_storage_information
      %Q{
        SELECT trim(a.name) as table_name, 
        decode(b.mbytes,0,0,((b.mbytes/part.total::decimal)*100)::decimal(5,2)) as pct_of_total, 
       (case when a.rows = 0 then NULL else ((a.rows - pgc.reltuples)::decimal(19,3)/a.rows::decimal(19,3)*100)::decimal(5,2) end) as pct_stats_off
      from ( select db_id, id, name, sum(rows) as rows, 
      sum(rows)-sum(sorted_rows) as unsorted_rows from stv_tbl_perm a group by db_id, id, name ) as a 
      join pg_class as pgc on pgc.oid = a.id
      join pg_namespace as pgn on pgn.oid = pgc.relnamespace
      left outer join (select tbl, count(*) as mbytes 
      from stv_blocklist group by tbl) b on a.id=b.tbl
      inner join ( SELECT   attrelid, min(case attisdistkey when  't' then attname else null end)  as "distkey",min(case attsortkeyord when 1 then attname  else null end ) as head_sort , max(attsortkeyord) as n_sortkeys, max(attencodingtype) as max_enc   FROM  pg_attribute group by 1) as det 
      on det.attrelid = a.id
      inner join ( select tbl, max(Mbytes)::decimal(32)/min(Mbytes) as ratio from
      (select tbl, trim(name) as name, slice, count(*) as Mbytes
      from svv_diskusage group by tbl, name, slice ) 
      group by tbl, name ) as dist_ratio on a.id = dist_ratio.tbl
      join ( select sum(capacity) as  total
        from stv_partitions where part_begin=0 ) as part on 1=1
      where mbytes is not null 
      and pgn.nspname = '#{schema}'
      order by  mbytes desc;}
    end


  end

end
