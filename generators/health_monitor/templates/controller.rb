class <%= class_name %>Controller < ApplicationController
  acts_as_health_monitor

  # Built in checks
  monitor_health :schema_check, :database_check#, :ey_agent_check

  # Refer to the README at http://github.com/blythedunham/health_monitor
  # for more examples
  #   #Make sure monit and 'myspecial cron task' is running
  #   monitor_process :monit, :myspecialcrontask
  #
  #   monitor_health :user_check
  #   # Monitor email sending. Fail if it exceeds 4 minutes

  #   monitor_health :email,
  #     :timeout => 240000 # Fail this test if it exceeds 4 minutes
  #     :method => lambda{ |controller|  ActionMailer::Base.deliver_my_mail('blah') }
  #
  #   # Display the results of system df call with the results
  #   monitor_health :check_disk, :description => 'Check Disk status' do |controller|
  #     results = `df`
  #     status = $? == 0 ? :success : :failure  # base result on return code
  #     { :status => status, :message => "DF: #{results}" }
  #   end
  #
  #   protected
  #   def user_check; User.first; end

  <% for action in actions -%>
  def <%= action %>
  end

  <% end -%>

end
