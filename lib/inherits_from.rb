require 'active_record'

# +inherits_from+ is an +ActiveRecord+ plugin designed to allow simple multiple table (class) inheritance.
# 
# Example:
#   class Product < ActiveRecord::Base
#     inherits_from :product
#   end
#
#   class Book < ActiveRecord::Base
#     inherits_from :product
#   end
#
#   class Video < ActiveRecord::Base
#     inherits_from :product
#   end
#
#   book = Book.find(1)
#   book.name => "Agile Development with Rails"
#   book.author => "Dave Thomas"
#
#   video = Video.find(2)
#   book.name => "Twilight Zone Season 1"
#   book.actors => "Rod Serling"

class ActiveRecord::Base
  attr_reader :reflection
  
  # Creates an inheritance association and generates proxy methods in the inherited object for easy access to the parent.
  # Currently, the options are ignored.
  #
  # Example:
  #   class Book < ActiveRecord::Base
  #     inherits_from :product
  #   end
  def self.inherits_from(association_id, options = {})
    belongs_to association_id
    validates_associated association_id
    
    reflection = create_reflection(:belongs_to, association_id, options, self)
    
    association_class = Object.const_get(reflection.class_name)
    
    inherited_column_names = association_class.column_names.reject { |c| self.column_names.grep(c).length > 0 || c == "type"}

    inherited_reflections = association_class.reflections.map { |key,value| key.to_s }
    
    (inherited_column_names + inherited_reflections).each do |name|
    	define_method(name) do
    		init_inherited_assoc(association_id)
    		klass = send(association_id)
      
    		klass.send(name)
    	end
    
    	define_method("#{name}=") do |new_value|
    		init_inherited_assoc(association_id)
    		klass = send(association_id)
      
    		klass.send("#{name}=", new_value)
    	end
    end
    
    inherited_reflections.each do |name|
    	%w{ build create }.each do |method|
    		define_method("#{method}_#{name}") do |*params|
	    		init_inherited_assoc(association_id)
    			klass = send(association_id)
      
    			klass.send("#{method}_#{name}", *params)
    		end
    	end
    	
    end
    
    before_callback = <<-end_eval
      init_inherited_assoc("#{association_id}")
      instance_variable_get("@#{association_id}").save
    end_eval
    
    before_create(before_callback)
    before_update(before_callback)
  end
  
  private
  # Ensures that there is an association to access, if not, creates one.
  def init_inherited_assoc(association_id)
    if new_record? and instance_variable_get("@#{association_id}").nil?
      send("build_#{association_id}")
      instance_variable_get("@#{association_id}").type = self.class.to_s
    end
  end
end
