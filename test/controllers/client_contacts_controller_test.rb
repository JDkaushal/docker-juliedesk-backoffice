require 'test_helper'

class ClientContactsControllerTest < ActionController::TestCase
  test "should get fetch" do
    get :fetch
    assert_response :success
  end

  test "should get synchronize" do
    get :synchronize
    assert_response :success
  end

end
