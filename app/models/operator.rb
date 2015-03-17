class Operator < ActiveRecord::Base

  def password=(value)
    self.salt = SecureRandom.base64(8)
    self.encrypted_password = Digest::SHA2.hexdigest(self.salt + value)
  end

  def password_correct? password
    self.encrypted_password == Digest::SHA2.hexdigest(self.salt + password)
  end
end