class Video < ActiveRecord::Base
  inherits_from :product
  
  validates_presence_of :name, :price, :minutes, :starring
end