class Admin::MySettingsController < ApplicationController
  def update

    params[:settings].each do |setting_name, setting_value|
      MySettings[setting_name] = setting_value
    end

    render json: true
  end
end
