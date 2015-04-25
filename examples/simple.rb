require "monatomic/autorun"

class Post
  include Monatomic::Model

  set readable: true
  set writable: -> (user) { user.is(:admin) or hot < 10 }
  set display_name: "帖子"
  set represent_field: :title

  field :title, {
    type: :string,
    display: "标题",
    validation: :presence,
    readable: :everyone,
  }
  field :hot, type: :integer, readable: -> { hot < 15 }
  field :date, type: :date, display: "日期"
end
