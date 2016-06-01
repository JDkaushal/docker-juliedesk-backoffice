class Admin::StatsController < AdminController
  def main
    params[:date] ||= DateTime.now.to_s
    date = DateTime.parse(params[:date])
    @data = {}
    (-3..0).map do |month|
      @data[(date + month.months).strftime("%Y-%m-01")] = ApplicationHelper.messages_and_delay_stats date + month.months, params[:exclude].present?
    end
  end

  def production

  end
end