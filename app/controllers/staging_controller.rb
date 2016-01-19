class StagingController < ApplicationController

  before_action :check_staging_env

  private

  def check_staging_env
    redirect_to root_path unless ENV['STAGING_APP']
  end

end