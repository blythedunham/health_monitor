module HealthMonitor
  module BuiltInChecks
    protected

    # Check the schema and sort by casted version number
    def sorted_schema_check; schema_check(:cast => true); end

    # Check the schema version
    # === Options
    #  <tt> :sql </tt> - the sql to use for the schema check
    #  <tt> :cast </tt> - cast the version to integer. Use for mysql non timestamped migrations if collation is not set.
    #  <tt> :order </tt> - the order by sql for selecting the current version
    #  <tt> :table </tt> - the table name. Defaults to schema_migrations.
    def schema_check( options = {} )

      sql = options[:sql]
      sql||= begin
        order_sql = if options[:order]
          options[:order]
        elsif options[:cast] || 
          (!ActiveRecord::Base.timestamped_migrations && ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::MysqlAdapter))
          "CAST(version as unsigned) DESC"
        else
          "version DESC"
        end
        table = options[:table] || (Rails::VERSION::STRING >= '2.1.0' ? 'schema_migrations' : 'schema_info')

        options[:sql] || "select version from #{table} order by #{order_sql} LIMIT 1"
      end
      
      version    = ActiveRecord::Base.connection.select_value( sql )

      {
        :status       => :success,
        :message      => "Schema version #{version}",
        :description  => 'Check database connection and schema'
      }
    end

    # Check db connection
    def database_check
      {
        :status => ActiveRecord::Base.connection && ActiveRecord::Base.connection.active?,
        :description => 'Active Database connection'
      }
    end

    # Call ey-agent to return nginx or apache status as well as database status
    def ey_agent_check
      results = {
        :description => 'Run ey-agent to monitor haproxy and monitor'
      }

      agent_results = JSON.load( `sudo ey-agent` )

      results.update(
        :message => agent_results.inspect,
        :status => agent_results && agent_results.any?{|k,v| v == 'down' }
      )
    rescue => e
      return results.update( :status => :failure, :exception => e )
    end

    # return true if the pid is alive
    def pid_alive?( pid, options = {} )
      `#{'sudo' if options[:sudo]} kill -0 #{pid}; echo $?`.chomp.to_i == 0
    end

    # ideas for this came from the ey-flex gem
    # +process_name+ - name of the process to monitor
    # === Options
    # +sudo+ - (default false) set to true to run pgrep as sudo
    # +pattern+ - specify a pattern to match (pgrep -f) instead of the process_name
    # +arguments+ - additional arguments to pgrep "-o root,blah -a"
    def process_alive?( process_name, options = {})
      return if process_name == ''

      cmd = []
      cmd << 'sudo' if options[:sudo]
      cmd << 'pgrep'
      cmd << options[:arguments].to_s if options[:arguments]
      cmd << "-f" if options[:pattern]
      cmd << (options[:pattern].is_a?( String ) ? options[:pattern] : process_name)

      pids = `#{cmd.join(' ')}`.split("\n")
      !pids.empty? && pids.all? {|p| pid_alive?( p )}
    end

    # Return a health monitor hash of status and description for
    # monitoring the specified process
    def process_health( process_name, options = {} )
      {
        :status => process_alive?( process_name, options ),
        :description => "Check that process #{process_name} is alive"
      }
    end
  end
end