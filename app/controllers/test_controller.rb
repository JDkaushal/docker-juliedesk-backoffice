class TestController < ApplicationController

  layout "test"

  before_action :only_admin

  def js

  end

  def templates

  end

  def template_generation

  end
end