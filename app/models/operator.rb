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


end