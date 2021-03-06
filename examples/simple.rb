require "monatomic"

class Post
  include Monatomic::Model

  set readable: true
  set writable: -> (user) { user.is(:admin) or hot < 10 }
  set display_name: "帖子"
  set represent_field: :title
  set display_fields: %w[ title hot date created_by_id rate ]
  set search_fields: %w[ title body ]
  set default_sort: "-updated_at"

  field :title, {
    type: :string,
    display: "标题",
    validation: :presence,
    readable: :everyone,
  }
  field :hot, type: :integer, readable: -> { hot < 15 }
  field :date, type: :date, display: "日期"
  field :body, type: :text, display: "正文"
  field :rate, type: :number_prompt, in: (1..5).to_a
end
