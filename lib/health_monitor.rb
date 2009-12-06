require File.dirname(__FILE__) + "/health_monitoring"
ActionController::Base.extend HealthMonitoring::ActsAsHealthMonitor
