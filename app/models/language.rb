class Language
  extend Category::ClassMethods
  include Category::InstanceMethods

  @@SUBCATEGORIZABLE = false
  def self.all_by_name
    return @@all
  end

end
