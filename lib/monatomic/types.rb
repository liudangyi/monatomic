module Monatomic
  Types = {
    string: {
      default: "",
      storage: String,
      presenter: -> { h value }
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
  }
end
