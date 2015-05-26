class Operator < ActiveRecord::Base

  has_many :locked_messages_thread, :foreign_key => 'locked_by_operator_id', class_name: "MessagesThread"
  def password=(value)
    self.salt = SecureRandom.base64(8)
    self.encrypted_password = Digest::SHA2.hexdigest(self.salt + value)
  end

  def password_correct? password
    self.encrypted_password == Digest::SHA2.hexdigest(self.salt + password)
  end
end