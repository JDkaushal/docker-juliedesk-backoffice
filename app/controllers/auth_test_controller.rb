class AuthTestController < ApplicationController
  skip_before_action :authenticate
  before_action :authenticate_ja, only: [:index]

  def index

  end
end