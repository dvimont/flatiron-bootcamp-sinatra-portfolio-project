module Subcategory
  extend Category::ClassMethods
  include Category::InstanceMethods

 # Subcategory objects don't contain their own attributes, instead inheriting
 #   attributes from owner_object. Subcategory is just a container for their
 #   audiobook collections that belong to the subcategorizing entity.
 # For example, an object of Genre might have @name == "fiction", and it in
 #   turn contains an @authors array of subcategory objects representing
 #    authors with "fiction" works. One such subcategory object might have an
 #    @owner_object field set to Author object == "Mark Twain", and the
 #    object would contain @audiobooks, @audiobooks_by_date, and @audiobooks_by_title
 #    SortedSets containing fiction works by Mark Twain.
 module InstanceMethods
   attr_accessor :owner_object
 end

end
