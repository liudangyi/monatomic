require 'securerandom'
require 'digest'

class User < Monatomic::Model
  display "用户"

  field :email, type: :string, validation: [:presence, :uniqueness], display: "用户 ID"
  field :name, type: :string, default: "未设定", display: "姓名"
  field :encrypted_password, type: :string, writable: [], readable: []
  field :roles, type: :tags, default: [:everyone], display: "角色"

  def password=(new_password)
    salt = SecureRandom.base64(6)
    self.encrypted_password = salt + ":" + Digest::SHA256.base64digest(salt + new_password)
  end

  def validate_password(password)
    return false if encrypted_password.blank?
    salt, pass = encrypted_password.split(":")
    pass == Digest::SHA256.base64digest(salt + password)
  end

end
