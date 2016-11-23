require 'test_helper'

class EntriesControllerTest < ActionDispatch::IntegrationTest
	
  test "should get index" do
    get entries_url(feeds(:ny_times))
    assert_response :success
  end

end
