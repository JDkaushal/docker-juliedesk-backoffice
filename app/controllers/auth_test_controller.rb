class AuthTestController < ApplicationController
  skip_before_action :authenticate
  before_action :authenticate_ja

  def index

  end

  def test_get
    render plain: "GET is working."
  end

  def test_post
    render plain: "POST is working."
  end
end