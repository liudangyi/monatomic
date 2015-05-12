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
    },
    text: {},
    prompt: {
      presenter: -> { h value }
    },
    enumeration: {
      presenter: -> { h value }
    },
    number_enumeration: {
      storage: Float,
      presenter: -> { h value },
      editor: :enumeration
    },
  }
end
