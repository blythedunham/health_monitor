
require File.dirname(__FILE__) + "/health_monitor/built_in_checks"
require File.dirname(__FILE__) + "/health_monitor/health_monitoring"

ActionController::Base.extend HealthMonitor::HealthMonitoring::ActsAsHealthMonitor
