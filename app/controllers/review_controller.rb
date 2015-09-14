class ReviewController < ApplicationController
  before_filter :only_admin

  layout "review"

end
