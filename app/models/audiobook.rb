class Audiobook
  @@all = SortedSet.new
  @@works_in_progress = SortedSet.new
  @@all_by_gutenberg_id = HashWithBsearch.new # used to build GenreGutenberg
  @@solo_works_by_date = HashWithBsearch.new(:descending) # newest solos
  @@group_works_by_date = HashWithBsearch.new(:descending) # newest group works

  def self.mass_initialize(hash_array)
    hash_array.each{ |hash| Audiobook.new(hash) }
  end

  def self.all
    return @@all
  end

  def self.all_by_gutenberg_id
    return @@all_by_gutenberg_id
  end

  def self.works_in_progress
    return @@works_in_progress
  end

  def self.solo_works_by_date
    return @@solo_works_by_date
  end

  def self.group_works_by_date
    return @@group_works_by_date
  end

  def self.list_all
    self.all.each {|audiobook| puts audiobook.to_s }
  end

  attr_accessor :id, :url_librivox, :title, :date_released, :url_text,
                :language, :authors_hash, :readers_hash, :genres_csv_string,
                :gutenberg_id, :gutenberg_subjects, :url_cover_art, :url_iarchive,
                :http_error
  attr_reader :language_object, :authors, :readers, :genres_librivox, :genres_gutenberg

  def initialize(attributes)
    self.add_attributes(attributes)
    # only completed audiobooks have a url_librivox value
    if (self.url_librivox.nil? || self.url_librivox.empty? ||
                  # must be in librivox.org domain
                  !self.url_librivox[/^https?:\/\/librivox.org/] ||
                  # must NOT have multiple directories after domain
                  self.url_librivox[/^https?:\/\/librivox.org\/.+\/.+/])
      @@works_in_progress.add(self)
    else
      if self.http_error.nil?
        @@all.add(self)
      else
        puts "HTTP ERROR for audiobook (#{self.url_librivox}): " + self.http_error
      end
    end
  end

  def add_attributes(attributes)
    attributes.each {|key, value|
      if value.is_a?(String) && value.start_with?("http:")
        value = "https" + value[4,value.length]
      end
      self.send(("#{key}="), value)
    }
    if !self.gutenberg_id.nil?
      @@all_by_gutenberg_id[self.gutenberg_id] = self # to scrape Gutenberg xml files
    end
  end

  def build_category_objects
    if !self.readers_hash.nil? && !self.readers_hash.empty?
      @readers = Reader.mass_initialize(self.readers_hash)
      @readers.each{|reader| reader.add_audiobook(self)}
    end
    if !self.language.nil? && !self.language.empty?
      @language_object = Language.create_or_get_existing(self.language)
      @language_object.add_audiobook(self)
    end
    if !self.authors_hash.nil? && !self.authors_hash.empty?
      @authors = Author.mass_initialize(self.authors_hash)
      @authors.each{|author| author.add_audiobook(self)}
    end
    if !self.genres_csv_string.nil? && !self.genres_csv_string.empty?
      @genres_librivox = GenreLibrivox.mass_initialize(self.genres_csv_string)
      @genres_librivox.each{|genre_librivox| genre_librivox.add_audiobook(self)}
    end
    if !self.gutenberg_subjects.nil? && !self.gutenberg_subjects.empty?
      @genres_gutenberg = GenreGutenberg.mass_initialize(self.gutenberg_subjects)
      @genres_gutenberg.each{|genre_gutenberg| genre_gutenberg.add_audiobook(self)}
    end
  end

  def build_solo_group_hashes
    if !self.readers.nil? && self.readers.size == 1
      @@solo_works_by_date[self.date_released + self.title[0,10]] = self
    else
      if !self.date_released.nil? && !self.title.nil?
        @@group_works_by_date[self.date_released + self.title[0,10]] = self
      end
    end
  end

  def to_s()
    output_string = "\n" +
        :id.to_s + ": " + self.id +
        "\n  " + :url_librivox.to_s + ": " + self.url_librivox +
        "\n  " + :title.to_s + ": " + self.title +
        "\n  " + :authors_hash.to_s + ": " + self.authors_hash.to_s +
#        "\n  " + :readers_hash.to_s + ": " + self.readers_hash.to_s +
#        "\n  " + :language.to_s + ": " + self.language.to_s +
#        "\n  " + :genres_csv_string.to_s + ": " + self.genres_csv_string +
        "\n  " + :date_released.to_s + ": " + self.date_released
    if self.http_error != nil
      output_string += "\n  " + :http_error.to_s + ": " + self.http_error
    end
    return output_string
  end

  def <=>(other)
    return self.id <=> other.id
  end
end
