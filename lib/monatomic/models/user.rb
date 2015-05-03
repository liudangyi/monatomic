require 'securerandom'
require 'digest'

class User
  include Monatomic::Model

  set display_name: "用户"
  set represent_field: -> { name + " (" + uid + ")" }
  set display_fields: %w[ uid name roles created_by_id created_at ]

  set writable: -> (user) { user.is(:admin) or id == user.id }
  set deletable: false

  field :uid, type: :string, validation: [:presence, :uniqueness], display: "用户 ID", writable: :admin
  field :name, type: :string, default: "未设定", display: "姓名"
  field :encrypted_password, writable: false, readable: false
  field :password, type: :password, display: "密码", readable: false
  field :roles, type: :tags, default: %w[ everyone ], display: "角色", writable: :admin

  def password=(new_password)
    salt = SecureRandom.base64(6)
    self.encrypted_password = salt + ":" + Digest::SHA256.base64digest(salt + new_password)
  end

  def validate_password(password)
    return false if encrypted_password.blank?
    salt, pass = encrypted_password.split(":")
    pass == Digest::SHA256.base64digest(salt + password)
  end

  def is(role)
    role.to_s.in? roles
  end

end
