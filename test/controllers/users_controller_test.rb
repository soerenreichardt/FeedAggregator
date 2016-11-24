require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get signup_path
    assert_response :success
  end

  test "should get dashboard if logged in" do
  	get login_path
  	log_in_as(users(:michael), remember_me: '0')
  	get dashboard_path
  	assert_response :success
  end

end