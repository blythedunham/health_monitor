class <%= class_name %>Controller < ApplicationController
  acts_as_health_monitor

  # Refer to the README at http://github.com/blythedunham/health_monitor
  # for more examples

  #   # montior the database connection
  #   monitor_health :database, :description => 'Check database connection'
  #
  #   # Monitor email sending. Fail if it exceeds 4 minutes
  #   monitor_health :email,
  #   :timeout => 240000 # Fail this test if it exceeds 4 minutes
  #   :method => lambda{ |controller|  ActionMailer::Base.deliver_my_mail('blah') }
  #
  #   # Display the results of system df call with the results
  #   monitor_health :check_disk, :description => 'Check Disk status' do |controller|
  #     results = `df`
  #     status = $? == 0 ? :success : :failure  # base result on return code
  #     { :status => status, :message => "DF: #{results}" }
  #   end
  #
  #   protected
  #   def database; ActiveRecord::Base.connection; end
  #

  <% for action in actions -%>
  def <%= action %>
  end

  <% end -%>
end
