# = Health Monitor 
# Monitor individual aspects of your rails application's health
#
# Most rails applications have many additional moving parts of which the health cannot be assessed with 
# simply pinging the (hopefully page cached) homepage 
#
# For example, 
# * Is Email is sent successfully?
# * Is the SMS gateway alive and you bought sufficient credits?
# * All database connections are alive? Backgroundrb down again?
# * The cloud computing setup jacked the imagemagick? Again?
# * You are running out of disk space and there are no more file descriptors for your
# * The git SHA and version is what ?
#
# Health Monitor adds a single controller action to generate an html, js, or xml report with details of *all* 
# your custom defined health checks. An error response code (500 server error) indicates failure
# when any monitored feature fails or exceeds the custom timeout definition. Health monitor is easier to setup than
# custom server side cron tasks and adds the advantage of exercising more code since everything from your load balancer 
# to nginx to mongrels must be happily shoving rubies around to get that 200 oh boy success message.
# So ping away, grab a beer and know that hey, you might be too drunk but at least you will know your application 
# is sick before your clients do.
# 
# ====Examples
#
# class HealthMonitorController < ApplicationController
#   acts_as_health_monitor
#
#   # montior the database connection
#   monitor_health :database, :description => 'Check database connection'
#
#   # Monitor email sending. Fail if it exceeds 4 minutes
#   monitor_health :email,
#     :timeout => 240000 # Fail this test if it exceeds 4 minutes
#     :method => lambda{ |controller|  ActionMailer::Base.deliver_my_mail('blah') }
#
#   # Display the results of system df call with the results
#   monitor_health :check_disk, :description => 'Check Disk status' do |controller|
#     results = `df`
#     status = $? == 0 ? :success : :failure
#     { :status => status, :message => "DF: #{results}" }
#   end
#
#   protected
#   def database; ActiveRecord::Base.connection; end
#
# end
#
# === +monitor_health+ Options
# <tt>:description</tt> - description of the task
# <tt>:message</tt> - Defaults to SUCCESS or FAILED!
#   Additional information that is either a string or a hash with keys <tt>:success</tt> and <tt>:failure</tt>
#   Message allows more custom result information, such as the number of servers queried or IP address
#   or git version.
#
# <tt>:timeout</tt> - Fails the health check if the total time exceeds <tt>:timeout</tt> milliseconds
# <tt>:method</tt> - The name of the method or a Proc to invoke. A block can be given as well.
# Defaults to the method with the feature name
#
# === Monitored Methods
# The proc or method defined should return its status as one of the following:
# * true or false indicating success or failure
#   monitor_health :mymonitor, :method => { |controller| ...do something ... ; true }
#
#   monitor_health :myothermonitor
#   def myothermonitor; false; end
#
# * a status symbol: of <tt>:success</tt>, <tt>:failure</tt>, <tt>:timeout</tt>, <tt>:skipped</tt>
#   monitor_health :mymonitor, :method => { |controller| ...do something ... ; :failure }
#
# * a hash of attributes including:
# ** <tt>:status</tt> must be a value listed above: defaults to failure
# ** <tt>:message</tt> Custom message with result data
# ** <tt>:description</tt> The task description
#
#   monitor_health :mymonitor do |controller|
#     ...do something ... ;
#     { :status => :success, :message => 'My custom results for server abc', :description => 'task description' }
#   end
#
# === Routes
# By default, the route resources are added (assume controller is named +HealthMonitorController+)
# The action defined is named +monitor_health+
#
# Base resource if show is not already defined by +health_monitor_url+
#   host/health_monitor.js?skip=mysql
#
# Member accessor +monitor_health_health_monitor+
#   host/health_monitor/monitor_health.js?only=thatone,thisone
#
# To disable and write your own routes, use +route+ option with +acts_as_health_monitor+
#   acts_as_health_monitor :route => false
#
module HealthMonitor
module HealthMonitoring
  def self.included( base )
    base.class_eval do
      extend HealthMonitoring::ClassMethods
      include HealthMonitor::BuiltInChecks
      cattr_accessor :monitored_features
      self.monitored_features ||= ActiveSupport::OrderedHash.new

      helper_method :monitored_features, :healthy?
      hide_action :monitored_features, :monitored_features=
    end
  end

  # by default, this is a singleton route
  # class HealthMonitor < ApplicationController
  #   acts_as_health_monitor
  # end
  #
  # ===Options
  # :route => false. Will disable autogenerating named paths and routes
  #
  # By default, the resouces are defined as (assume controller is named +HealthMonitorController+)
  # Base resource if show is not already defined by +health_monitor_url+
  #   host/health_monitor.js?skip=mysql
  #
  # Member accessor +monitor_health_health_monitor+
  #   host/health_monitor/monitor_health.js?only=thatone,thisone
  #
  module ActsAsHealthMonitor
    def acts_as_health_monitor( options = {} )
      include HealthMonitor::HealthMonitoring unless method_defined?( :health_monitor )
      
      setup_health_monitor_routes( options.delete( :route ) )
    end

    def setup_health_monitor_routes( route )
      return if route == false

      base_methods = if method_defined?( :show )
        :none
      else
        alias_method :show, :monitor_health
        :show
      end

      ActionController::Routing::Routes.draw do |map|
        map.resource controller_name, :controller => controller_name, :only => base_methods, :member => { :monitor_health => :get }
      end
    end
  end

  module ClassMethods
    def monitor_health( *features, &block )
      options = features.extract_options!
      options.symbolize_keys!
      options[:method] = block if block_given?
      features.each {|name|  self.monitored_features[ name.to_sym ] = options }
    end

    # Monitor a server process
    # +process_name+ - name of the process to monitor
    # === Options
    # +sudo+ - (default false) set to true to run pgrep as sudo
    # +pattern+ - specify a pattern to match (pgrep -f) instead of the process_name
    # +arguments+ - additional arguments to pgrep "-o root,blah -a"
    # === Examples
    #   monitor_process :monit, :someproc, :sudo => true
    #   monitor_process :mongod, :pattern => 'mongodb.*slave'
    def monitor_process( *processes )
      options = processes.extract_options!
      options.symbolize_keys!

      processes.each do |process_name|
        monitor_name = "check_process_#{process_name.to_s.underscore}".to_sym
        class_eval <<-END_SRC, __FILE__, __LINE__
def #{monitor_name}
  process_health( #{process_name.inspect}, monitored_features[#{monitor_name.inspect}] )
end
END_SRC

        monitor_health monitor_name, options
      end
    end
  end

  # Show a status page showing the health of monitored features
  # Returns a 404 if any features have a success of unsuccessful
  #
  # Skip features: z2live.com/health/status?skip=mongo,mysql
  # Include features: z2live.com/health/status?feature=mongo
  def monitor_health
    find_features
    @results = @features.inject({}) do |results, feature_name|
      results[ feature_name ] = monitor_health_of( feature_name )
      results
    end
    healthy? ? on_healthy : on_unhealthy
    render_health
  end

  protected
  def monitor_health_of( feature_name )
    feature_status = { :name => feature_name }
    result = nil
    feature_status[ :time ] = Benchmark.ms { result = invoke_health_check( feature_name ) }
    report_health_status!( feature_status, result )
  end

  def invoke_health_check( feature_name )
    case method = monitored_features[ feature_name ][ :method ]
      when Proc, Method then method.call( self)
      when NilClass then send( feature_name )
    else send( method )
    end
  rescue => e
    logger.error(
      "Health Monitor Error for feature '#{feature_name}': " +
      " ##{e.inspect}\n #{e.backtrace.join("\n")}"
    ) if defined?( logger ) && logger

    return { :status => :failure, :exception => e }
  end

  def healthy?
    (@results||{}).all?{ |name, result| result[:status] == :success }
  end

  #response code
  def healthy_response_code()    200; end
  def unhealthy_response_code()  500; end

  #callbacks
  def on_healthy()   end
  def on_unhealthy() end

  def health_check_template
    File.join( File.dirname(__FILE__), "/../../generators/health_monitor/templates/_health_monitor.html.erb" )
  end

  def health_response_code
    healthy? ? healthy_response_code : unhealthy_response_code
  end

  # Render the html file
  def render_health_html
    render :file => health_check_template,   :status => health_response_code
  end

  # Render the json file
  def render_health_json
    render :text => @results.values.to_json, :status => health_response_code
  end

  # Render the xml file
  def render_health_xml
    render :xml  => @results.values,         :status => health_response_code
  end

  # Render the result
  def render_health
    return if performed?

    respond_to do |format|
      format.html { render_health_html }
      format.js   { render_health_json }
      format.xml  { render_health_xml  }
    end
  end



  # Skip features by appending skip=mongo,fun,etc
  # Include features by appending feature=mongo,urban_airship,etc to filter
  def find_features
    @features = if params[ :only ]
      params[ :only ].to_s.split( "," ).collect( &:to_sym ).uniq

    elsif skip = params[ :skip ] || params[ :exclude ]
      monitored_features.keys - skip.to_s.split( "," ).collect( &:to_sym )

    else
      monitored_features.keys
    end
  end

  def fail_health_timeout!( feature_status )
    timeout = monitored_features[ feature_status[:name] ][:timeout]
    if timeout && feature_status[:time].to_f >= timeout
      feature_status.update(
        :status => :timeout,
        :message => "Timeout: Exceeded #{timeout} ms"
      )
    end

    #Adjust time to seconds
    feature_status[ :time ] = ("%.4f" % (feature_status[ :time ] / 1000)).to_f

    feature_status
  end

  def set_default_health_status!( feature_status )
    monitor_defaults = monitored_features[ feature_status[ :name ] ]
    feature_status[ :description ] ||= monitor_defaults[ :description ]
    health_monitor_message!( feature_status )
  end

  def health_monitor_message!( feature_status )
    feature_status[ :message ] ||= monitored_features[ feature_status[ :name ] ][ :message ]
    feature_status[ :message ] = feature_status[:message][ feature_status[:status] ]  if feature_status[:message].is_a?( Hash )
    feature_status[ :message ] ||= feature_status[:status].to_s.upcase
    feature_status[ :message ] << " Error: #{feature_status[:exception]}" if feature_status[:exception]
    feature_status
  end

  def report_health_status!( feature_status, result )

    # update the hash with the result hash
    case result
      when Hash then feature_status.update( result )
      else feature_status[ :status ] = result
    end

    # symbolize variables if strings
    # convert false to :failure
    # otherwise the existance of any object indicates success
    feature_status[:status] = case feature_status[:status].to_s
      when /(failure|success|timeout|skipped)/ then feature_status[:status].to_sym
      when 'false' then :failure
      else !!feature_status[:status] ? :success : :failure
    end
  
    fail_health_timeout!( feature_status )
    set_default_health_status!( feature_status )
  end
end
end