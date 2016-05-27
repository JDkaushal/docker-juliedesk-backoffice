class Operator < ActiveRecord::Base

  has_many :locked_messages_thread, :foreign_key => 'locked_by_operator_id', class_name: "MessagesThread"

  has_many :operator_actions_groups
  has_many :operator_presences

  PRIVILEGE_OPERATOR = nil
  PRIVILEGE_ADMIN = "admin"
  PRIVILEGE_SUPER_OPERATOR_LEVEL_1 = "super_operator_level_1"
  PRIVILEGE_SUPER_OPERATOR_LEVEL_2 = "super_operator_level_2"


  def password=(value)
    self.salt = SecureRandom.base64(8)
    self.encrypted_password = Digest::SHA2.hexdigest(self.salt + value)
  end

  def password_correct? password
    self.encrypted_password == Digest::SHA2.hexdigest(self.salt + password)
  end

  def self.privilege_descriptions
    {
        PRIVILEGE_OPERATOR => "Operator level 1",
        PRIVILEGE_SUPER_OPERATOR_LEVEL_1 => "Operator level 2",
        PRIVILEGE_SUPER_OPERATOR_LEVEL_2 => "Operator level support",
        PRIVILEGE_ADMIN => "Admin"
    }
  end

  def stars
    if privilege == PRIVILEGE_SUPER_OPERATOR_LEVEL_1
      "*"
    elsif privilege == PRIVILEGE_SUPER_OPERATOR_LEVEL_2
      "**"
    end
  end

  def level
    {
      PRIVILEGE_SUPER_OPERATOR_LEVEL_1 => 10,
      PRIVILEGE_SUPER_OPERATOR_LEVEL_2 => 100,
      PRIVILEGE_ADMIN => 1000
    }[privilege] || 0
  end

  def level_string
    {
        PRIVILEGE_OPERATOR => 1,
        PRIVILEGE_SUPER_OPERATOR_LEVEL_1 => 2,
        PRIVILEGE_SUPER_OPERATOR_LEVEL_2 => 3,
        PRIVILEGE_ADMIN => "Admin"
    }[privilege]
  end

  def formatted_presences_for_day day
    day_presences = presences_for_day(day)
    day_presences.group_by(&:is_review).map do |is_review, mode_day_presences|
      ops = mode_day_presences.map{|op|
        date = op.date.in_time_zone("Indian/Antananarivo")
        number = date.strftime("%H").to_i
        if date.min == 30
          number += 0.5
        end
        number
      }
      ranges = []
      ops.sort_by!{|op|
        if op >= 6
          op
        else
          op + 24
        end
      }
      while ops.length > 0
        current_op = ops.shift
        if ranges.length > 0 && current_op == ranges.last.last
          ranges[ranges.length - 1] = [ranges.last.first, (ranges.last.last + 0.5) % 24]
        else
          ranges << [current_op, (current_op + 0.5) % 24]
        end
      end
      ((is_review)?"Review: ":"") + ranges.map{|range|
        "#{range.first.floor}h#{((range.first - range.first.floor) == 0.5)?"30":"00"} - #{range.last.floor}h#{((range.last - range.last.floor) == 0.5)?"30":"00"}"
      }.join(" / ")
    end.join(" & ")
  end

  def presences_for_day day
    start_date = day.in_time_zone("Indian/Antananarivo").beginning_of_day + 6.hours
    end_date = start_date + 24.hours
    operator_presences.select{|op|
      op.date >= start_date &&
          op.date < end_date
    }
  end

  def self.generate_operator first_name
    email = "#{first_name}@operator.juliedesk.com"
    password = "julie#{self.generate_random_string(4)}desk"

    Operator.create({
        email: email,
        name: first_name.capitalize,
        active: true,
        password: password
    })

    print "Username: #{email}\n"
    print "Password: #{password}\n\n\n"
  end


  def self.generate_random_string length
    o = [('a'..'z')].map { |i| i.to_a }.flatten
    (1..length).map { o[rand(o.length)] }.join
  end

  def self.generate_stats_data operator_ids, flagged_messages_thread_ids=nil
    operator_actions_groups = OperatorActionsGroup.where(operator_id: operator_ids)
    dates = {}
    (0..3).each do |i|
      dates["S#{(DateTime.now - i.weeks).strftime("%V")}"] = {start: (DateTime.now - i.weeks).beginning_of_week, end: (DateTime.now - i.weeks).end_of_week}
    end
    (0..3).each do |i|
      dates["#{(DateTime.now - i.months).strftime("%B")}"] = {start: (DateTime.now - i.months).beginning_of_month, end: (DateTime.now - i.months).end_of_month}
    end

    max_duration = 30 * 60

    unless flagged_messages_thread_ids
      flagged_server_messages_ids = []
      (0..3).each do |i|
        start_date = (DateTime.now - i.months).beginning_of_month
        end_date = (DateTime.now - i.months).end_of_month

        flagged_server_messages_ids += EmailServer.search_messages({
                                                                       after: start_date.to_s,
                                                                       before: end_date.to_s,
                                                                       labels: "flag",
                                                                       limit: 1000
                                                                   })['messages']['ids']
      end
      flagged_messages_thread_ids = Message.where(server_message_id: flagged_server_messages_ids).select(:messages_thread_id).distinct.map(&:messages_thread_id)
    end

    Hash[dates.map do |k, dates_hash|
      hours_count = OperatorPresence.where(operator_id: operator_ids, is_review: false).where("date > ? AND date < ?", dates_hash[:start], [DateTime.now, dates_hash[:end]].min).count / 2.0
      operator_actions_groups_for_dates = operator_actions_groups.where("initiated_at > ? AND initiated_at < ?", dates_hash[:start], dates_hash[:end])
      operator_actions_groups_count = operator_actions_groups_for_dates.count

      operator_action_groups_by_hour_ratio = operator_actions_groups_count / hours_count


      average_processing_time = operator_actions_groups_for_dates.average(:duration)
      average_processing_time_maxed = operator_actions_groups_for_dates.where("duration < ?", max_duration).average(:duration)


      actions_count = operator_actions_groups_for_dates.count
      reviewed_count = operator_actions_groups_for_dates.where(review_notation: [0, 1, 2, 3, 4, 5]).count
      errors_count = operator_actions_groups_for_dates.where(review_notation: [0, 1, 2, 3]).count

      actions_flagged_count = operator_actions_groups_for_dates.where(messages_thread_id: flagged_messages_thread_ids).count
      reviewed_flagged_count = operator_actions_groups_for_dates.where(messages_thread_id: flagged_messages_thread_ids).where(review_notation: [0, 1, 2, 3, 4, 5]).count
      errors_flagged_count = operator_actions_groups_for_dates.where(messages_thread_id: flagged_messages_thread_ids).where(review_notation: [0, 1, 2, 3]).count

      actions_non_flagged_count = actions_count - actions_flagged_count
      reviewed_non_flagged_count = reviewed_count - reviewed_flagged_count
      errors_non_flagged_count = errors_count - errors_flagged_count

      errors_rate = (
      (errors_flagged_count * actions_flagged_count * 1.0 / (reviewed_flagged_count + 1)) +
          (errors_non_flagged_count * actions_non_flagged_count * 1.0 / (reviewed_non_flagged_count + 1))
      ) / actions_count

      [k, {
          operator_action_groups_by_hour_ratio: operator_action_groups_by_hour_ratio,
          operator_action_groups_count: operator_actions_groups_count,
          operator_action_groups_count_per_operator: operator_actions_groups_count / OperatorPresence.where(operator_id: operator_ids, is_review: false).where("date > ? AND date < ?", dates_hash[:start], [DateTime.now, dates_hash[:end]].min).select(:operator_id).distinct.count / 2.0,
          average_processing_time: average_processing_time,
          average_processing_time_maxed: average_processing_time_maxed,
          notation_1_count: operator_actions_groups_for_dates.where(review_notation: 1).count,
          notation_2_count: operator_actions_groups_for_dates.where(review_notation: 2).count,
          notation_3_count: operator_actions_groups_for_dates.where(review_notation: 3).count,
          notation_4_count: operator_actions_groups_for_dates.where(review_notation: 4).count,
          notation_5_count: operator_actions_groups_for_dates.where(review_notation: [5, 6]).count,
          errors_rate: errors_rate,
          updated_at: DateTime.now
      }]
    end]

  end


end