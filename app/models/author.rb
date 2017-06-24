class Author < Contributor
  extend Category::ClassMethods

  @@all_by_name = HashWithBsearch.new
  def self.all_by_name
    return @@all_by_name
  end
end
