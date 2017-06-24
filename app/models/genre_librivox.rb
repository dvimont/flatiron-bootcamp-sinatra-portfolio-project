class GenreLibrivox
  extend Category::ClassMethods
  include Category::InstanceMethods

  @@SUBCATEGORIZABLE = true
  
  def self.all_by_name
    return @@all
  end

  def self.mass_initialize(genres_csv_string)
    genres_librivox = Array.new

    genres_csv_string.split(",").each { |genre_string|
      genre_string.strip!
      if !genre_string.nil? && !genre_string.empty?
        genres_librivox.push(self.create_or_get_existing(genre_string))
      end
    }
    return genres_librivox
  end

  def self.to_s()
    return "Librivox Genre"
  end

end
