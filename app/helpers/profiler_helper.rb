module ProfilerHelper

  def print_time tag
    @time_reference ||= Time.now
    @times ||= []
    @times << {
        index: @times.length,
        tag: tag,
        time: Time.now,
        delay: Time.now - (@times.last.try(:[], :time) || @time_reference),
        total_delay: Time.now - @time_reference
    }
  end

  def print_all_times
    if !Rails.env.development?
      print({
                route: "#{params[:controller]}##{params[:action]}",
                times: @times
            }.to_json)
      print "\n"
    else
      print "-" * 50
      print "\n\n"
      print_arrays @times.map { |time|
                     [
                         time[:index],
                         time[:tag],
                         "#{time[:delay]}s",
                         "#{time[:total_delay]}s"
                     ]
                   }

      print "\n\n"
      print "-" * 50
      print "\n"
    end
  end

  def print_arrays arrays
    (0..arrays.first.length - 1).each do |i|
      max_length = arrays.map{|array| "#{array[i]}".length}.max + 5
      arrays.each do |array|
        array[i] = "#{array[i]}#{" " * (max_length - "#{array[i]}".length)}"
      end
    end

    arrays.each do |array|
      print array.join
      print "\n"
    end
  end
end
