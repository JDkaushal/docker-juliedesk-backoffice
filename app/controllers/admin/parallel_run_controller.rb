class Admin::ParallelRunController < AdminController

  def recap
    data = Message.parallel_run_recap
    @data = {
        stats: Message.parallel_run_stats(data),
        fields: data.first[:human].keys,
        data: data
    }
  end
end