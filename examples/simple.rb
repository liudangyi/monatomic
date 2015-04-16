require "monatomic/autorun"

class Post < Monatomic::Model
  display "帖子"

  readable :everyone
  writable :admin

  field :title, {
    type: :string,
    display: "标题",
    validation: :presence,
    readable: :everyone,
    writable: :manager,
  }
end
