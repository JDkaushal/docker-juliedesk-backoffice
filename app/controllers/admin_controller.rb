class AdminController < ApplicationController
  before_action :only_admin
end