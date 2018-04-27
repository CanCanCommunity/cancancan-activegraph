class Project
  include Neo4j::ActiveNode
  property :name, type: String
  # property :content, type: String

  # has_one :out, :author, type: :auther, model_class: :User
end

class Category
  include Neo4j::ActiveNode
  property :name, type: String
  property :visible, type: Boolean

  has_many :in, :articles, origin: :category
end

class Article
  include Neo4j::ActiveNode
  property :name, type: String
  property :published, type: Boolean
  property :secret, type: Boolean
  property :priority, type: Integer

  has_one :out, :category, type: :category
  has_many :in, :comments, origin: :article
  has_many :out, :mentions, type: :mention, model_class: :Mention
  has_one :out, :user, type: :user
end

class Mention
  include Neo4j::ActiveNode
  property :active, type: Boolean

  has_one :in, :article, type: :mention
  has_one :out, :user, type: :user
end

class Comment
  include Neo4j::ActiveNode
  property :spam, type: Boolean
  
  has_one :out, :article, type: :article
end

class User
  include Neo4j::ActiveNode
  property :name, type: String
  property :status, type: String

  has_many :in, :articles, origin: :user
  has_many :in, :mentions, origin: :user
  has_many :out, :friends, type: :friend, model_class: self
end

module Namespace
end

class Namespace::TableX
  include Neo4j::ActiveNode
  
  has_many :in, :table_zs, type: :table_x, model_class: 'Namespace::TableZ'
end

class Namespace::TableZ
  include Neo4j::ActiveNode
  
  has_one :out, :table_x, type: :table_x, model_class: 'Namespace::TableX'
  has_one :out, :user, type: :user
end