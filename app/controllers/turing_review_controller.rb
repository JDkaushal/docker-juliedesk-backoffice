class TuringReviewController < ApplicationController
  before_action :only_super_operator_level_2_or_admin

  layout "review"

end
