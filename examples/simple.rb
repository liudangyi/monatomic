require "monatomic/autorun"

class Post < Monatomic::Model
  set readable: :everyone
  set writable: [:admin, -> { hot < 10 }]
  set display_name: "帖子"
  set represent_field: :title

  field :title, {
    type: :string,
    display: "标题",
    validation: :presence,
    readable: :everyone,
  }
  field :hot, type: :integer, readable: -> { hot < 15 }
end
