module Monatomic
  Types = {
    string: {
      default: "",
      storage: String,
      presenter: -> { h value }
    },
    password: {
      presenter: -> { value.present? ? "******" : "" }
    },
    tags: {
      default: [],
      storage: Array
    },
    integer: {
      default: 0,
      storage: Integer,
      presenter: -> { value }
    },
    date: {
      default: -> { Date.today },
      storage: Date,
      presenter: -> { value }
    },
    time: {
      storage: Time, 
      presenter: -> { value.localtime.to_s(:db) }
    },
    object: { # relation
      storage: Object
    }
  }
end
