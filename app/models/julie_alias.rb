class JulieAlias < ActiveRecord::Base

  def generate_from
    "#{self.name} <#{self.email}>"
  end
end