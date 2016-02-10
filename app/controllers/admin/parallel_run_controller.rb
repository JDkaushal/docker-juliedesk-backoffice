class Admin::ParallelRunController < AdminController

  def recap
    data = MessageInterpretation.parallel_run_recap
    @data = {
        stats: MessageInterpretation.parallel_run_stats(data),
        fields: data.first[:human].keys,
        data: data
    }
  end

  def stats
    message_counts_hash = Hash[Message.select("COUNT(*), to_char(received_at, 'YYYY-MM-DD') as fdate").where(from_me: false).where("received_at > ?", (DateTime.now - 20.days).beginning_of_day).group("fdate").map do |r|
      [r.attributes['fdate'], r.attributes['count']]
                          end]

    message_interpretation_counts_hash = Hash[MessageInterpretation.joins(:message).select("COUNT(DISTINCT(message_interpretations.message_id)), to_char(messages.received_at, 'YYYY-MM-DD') as fdate").where("messages.from_me = 'f'").where("message_interpretations.raw_response IS NOT NULL").where("messages.received_at > ?", (DateTime.now - 20.days).beginning_of_day).group("fdate").map do |r|
      [r.attributes['fdate'], r.attributes['count']]
                                         end]


    days = []
    message_counts = []
    message_interpretation_counts = []
    ((DateTime.now - 20.days)..DateTime.now).each do |date|
      day = date.strftime("%Y-%m-%d")
      days << day
      message_counts << message_counts_hash[day] || 0
      message_interpretation_counts << message_interpretation_counts_hash[day] || 0
    end

    @data = {
        days: days,
        message_counts: message_counts,
        message_interpretation_counts: message_interpretation_counts,
        stats: MessageInterpretation.parallel_run_stats
    }
  end
end