class AdminController < ApplicationController
  before_filter :only_admin
end