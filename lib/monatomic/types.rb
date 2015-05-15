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
      storage: Object,
      presenter: -> { "<a href='#{path_for(search: "#{field.name}:#{value.id}")}'>#{h value.display_name}</a>" if value }
    },
    text: {},
    prompt: {
      presenter: -> { "<a href='#{path_for(search: "#{field.name}:#{value}")}'>#{h value}</a>" }
    },
    enumeration: {
      presenter: -> { "<a href='#{path_for(search: "#{field.name}:#{value}")}'>#{h value}</a>" }
    },
    number_prompt: {
      storage: Float,
      presenter: -> { "<a href='#{path_for(search: "#{field.name}:#{value}")}'>#{h value}</a>" },
      editor: :prompt
    },
    number_enumeration: {
      storage: Float,
      presenter: -> { "<a href='#{path_for(search: "#{field.name}:#{value}")}'>#{h value}</a>" },
      editor: :enumeration
    },
  }
end
