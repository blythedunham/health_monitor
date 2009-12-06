require 'helper'

#require 'shoulda/controller/macros'
class TestHealthMonitorController < ActionController::Base
  acts_as_health_monitor
  
  monitor_health :proc_test, 
                 :method => lambda{ |c| c.params[:fail] != 'true' }, 
                 :description => 'A proc test',
                 :message => {:success => "Successful test.", :failure => 'Failed test'}
                 
  monitor_health :block_test do |controller|
    @block_controller = controller
    { 
      :status => controller.send(:conditional_fail_test),
      :message => "Params are: #{controller.params[:fail]}",
      :description => 'A block test'
    }
  end
  
  monitor_health :conditional_fail_test
  monitor_health :exception_test

  protected
  def conditional_fail_test( key = :fail)
    params[key] != 'true'
  end

  def exception_test
    raise StandardError.new("Exception test") if params[:exception] == 'true'
    :success
  end
end

class TestHealthMonitorControllerTest < ActionController::TestCase
  
  def self.ping_monitor( testname, options = {} )
    
    context testname do
      expect_success = ![options[:fail], options[:exception]].include?( 'true' )
      setup do
        get :show, options
        @success = expect_success#![options[:fail], options[:exception]].include?( 'true' )
        @results = assigns(:results)
      end
      
      should_respond_with( expect_success ? 200 : 500 )

      should 'have the description' do
        assert_equal 'A proc test', @results[:proc_test][:description]
        assert_equal 'A block test', @results[:block_test][:description]
        assert_nil @results[:conditional_fail_test][:description]
      end
      
      should 'set default message based on test status' do
        result = @success ?  'SUCCESS' : 'FAILURE'
        assert_equal result, @results[:conditional_fail_test][:message], "Expect message #{@success} for #{@results[:conditional_fail_test]} "
      end
    
      if expect_success
        should 'set custom message on success to' do
          assert_equal 'Successful test.', @results[:proc_test][:message]
          assert_equal 'Params are: ',     @results[:block_test][:message]
        end
      else
        should 'set custom message on failure to' do
          assert_equal 'Failed test', @results[:proc_test][:message]
          assert_equal 'Params are: true',     @results[:block_test][:message]
        end
      end 

      should "have #{expect_success ? 'SUCCESS' : 'FAIL'} response" do
        @results.each do |k,v|
          expected_result = (k == :exception_test) || @success ? :success : :failure
          assert_equal expected_result, v[:status], "#{k} results #{v.inspect}. Status should be #{expected_result}" 
        end
      end

      yield if block_given?
    end
  end
  
  should_route :get, '/test_health_monitor.js', :action => :show, :format => "js", :controller => 'test_health_monitor'
  should_route :get, '/test_health_monitor/monitor_health', :controller => 'test_health_monitor', :action => :monitor_health

  ping_monitor 'health monitor web page' do
    should_respond_with_content_type :html
  end

  ping_monitor( 'monitor unhealthy app', :fail => 'true' ) do
    should_respond_with_content_type :html
  end

  ping_monitor 'monitor an unhealthy app with js', {:fail => 'true', :format => 'js'} do
    should_respond_with_content_type 'text/javascript'
  end

  ping_monitor 'monitor a healthy app with js', {:format => 'js'} do
    should_respond_with_content_type 'text/javascript'
  end
  
  ping_monitor 'monitor an unhealthy app with js', {:fail => 'true', :format => 'xml'} do
    should_respond_with_content_type :xml
  end

  ping_monitor 'monitor a healthy app with js', {:format => 'xml'} do
    should_respond_with_content_type :xml
  end
  
  context 'render a template if a test exception occurs' do
    setup do
      get :show, :exception => 'true'
      @results = assigns(:results)
    end
    should_respond_with_content_type :html
    should_respond_with 500

    should 'fail exception test' do
      assert_equal :failure, @results[:exception_test][:status]
    end
  end

end

