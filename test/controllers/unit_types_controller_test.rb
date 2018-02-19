require 'test_helper'

class UnitTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unit_type = unit_types(:one)
  end

  test "should get index" do
    get unit_types_url
    assert_response :success
  end

  test "should get new" do
    get new_unit_type_url
    assert_response :success
  end

  test "should create unit_type" do
    assert_difference('UnitType.count') do
      post unit_types_url, params: { unit_type: { active: @unit_type.active, name: @unit_type.name } }
    end

    assert_redirected_to unit_type_url(UnitType.last)
  end

  test "should show unit_type" do
    get unit_type_url(@unit_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_unit_type_url(@unit_type)
    assert_response :success
  end

  test "should update unit_type" do
    patch unit_type_url(@unit_type), params: { unit_type: { active: @unit_type.active, name: @unit_type.name } }
    assert_redirected_to unit_type_url(@unit_type)
  end

  test "should destroy unit_type" do
    assert_difference('UnitType.count', -1) do
      delete unit_type_url(@unit_type)
    end

    assert_redirected_to unit_types_url
  end
end
