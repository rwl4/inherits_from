class Book < ActiveRecord::Base
  inherits_from :product
  
  validates_presence_of :name, :pages
end