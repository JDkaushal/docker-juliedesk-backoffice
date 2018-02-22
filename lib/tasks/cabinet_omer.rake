namespace :cabinet_omer do
  task :compute_weekly_recap_cache => :environment do |t|
    data = []
    window_start_time = DateTime.now.beginning_of_week - 1.weeks
    window_end_time = window_start_time + 1.week

    %w"secreteriat.omer@gmail.com secretariat.omer.1@gmail.com secretariat.omer.2@gmail.com".each do |account_email|
      data += WeeklyRecapHelper.get_weekly_recap_data({
                                                          account_email: account_email,
                                                          window_start_time: window_start_time,
                                                          window_end_time: window_end_time
                                                      })
    end
    REDIS_FOR_ACCOUNTS_CACHE.set('omer_weekly_recap_data', data.to_json)
  end
end
