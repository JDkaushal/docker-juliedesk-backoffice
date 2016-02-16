class Admin::StatsController < AdminController
  def main
    params[:date] ||= DateTime.now.to_s
    date = DateTime.parse(params[:date])
    @data = ApplicationHelper.messages_and_delay_stats date, params[:exclude].present?
  end
end