
class HealthMonitorGenerator <  ControllerGenerator
  def initialize(runtime_args, runtime_options = {})
    runtime_args << 'health_monitor' if runtime_args.empty?
    super runtime_args, runtime_options
  end

  protected

  # Override the source path to read the parents templates for everything
  # except the controller
  def source_path(relative_source)
    original_source_root = self.source_root
    if relative_source != 'controller.rb'
      @source_root = File.join(self.class.lookup('Controller').path, 'templates')
    end
    super
  ensure
    @source_root = original_source_root
  end

  def banner
    "Usage: #{$0} health_monitor [controller_name] [options] \n  Default controller_name = HealthMonitorController]"
  end

end