module Category
  module ClassMethods
    # NOTE: CHAR_CONVERSION_ARRAY is not a comprehensive set of all possible "alternate versions" of capital letters.
    CHAR_CONVERSION_ARRAY =
      %w[ǍĄĂĀÆÅÄÃÂÀÁÄA ŒŐŎŌØÓÕÔÒÓÖO İĮĬĪĨǏÏÎÌÍI ŲŰŮŬŪŨÜÛÙÚÜU ĚĘĖĔĒËÊÈÉE ṠȘŠŞŜŚßS ƇČĊĈĆÇC ĐĎD ŇŅŃÑN ŻZ]

    def self.extended(base) # fires at start-up (during Class-level instantiation)
      base.class_variable_set(:@@all, HashWithBsearch.new)
    end

    def all
      return self.class_variable_get(:@@all)
    end

    def create_or_get_existing(id_string, attributes=nil)
      retrieved_object = self.all[id_string]
      if retrieved_object.nil?
        retrieved_object = self.new({id: id_string})
        if !attributes.nil?
          retrieved_object.add_attributes(attributes)
        end
        retrieved_object.add_self_to_class_collections
      end
      return retrieved_object
    end

    def get(id)
      return self.all[id]
    end

    # The following derived from https://grosser.it/2009/03/07/umlaut-aware-alphabetical-sorting/
    def convert_alt_chars_to_base(capitalized_text)
      CHAR_CONVERSION_ARRAY.each { |set|
        capitalized_text.gsub!(/[#{set[0..-2]}]/,set[-1..-1])
      }
      return capitalized_text
    end
  end

  module InstanceMethods
    attr_accessor :id
    attr_reader :audiobooks, :audiobooks_by_title, :audiobooks_by_date,
          :solo_works_by_title, :solo_works_by_date,
          :group_works_by_title, :group_works_by_date

    def initialize(attributes)
      self.add_attributes(attributes)
      @audiobooks = HashWithBsearch.new # default (id) order
      @audiobooks_by_title = HashWithBsearch.new # {|a,b| a.title <=> b.title}
      @audiobooks_by_date = HashWithBsearch.new(:descending)
      @solo_works_by_title = HashWithBsearch.new
      @solo_works_by_date = HashWithBsearch.new(:descending)
      @group_works_by_title = HashWithBsearch.new
      @group_works_by_date = HashWithBsearch.new(:descending)
    end

    def add_self_to_class_collections()
      self.class.all[self.id] = self
    end

    def add_attributes(attributes)
      attributes.each {|key, value| self.send(("#{key}="), value)}
    end

    def add_audiobook(audiobook)
      if self.audiobooks[audiobook.id] == nil # this audiobook not yet "registered" here
        self.audiobooks[audiobook.id] = audiobook
        title_key = audiobook.title
        if title_key.upcase.start_with?("THE ")
          title_key = title_key[4,title_key.length]
        end
        self.audiobooks_by_title[title_key] = audiobook
        self.audiobooks_by_date[audiobook.date_released] = audiobook
        if !audiobook.readers_hash.nil?
          if audiobook.readers_hash.size == 1
            self.solo_works_by_title[title_key] = audiobook
            self.solo_works_by_date[audiobook.date_released] = audiobook
          elsif audiobook.readers_hash.size > 1
            self.group_works_by_title[title_key] = audiobook
            self.group_works_by_date[audiobook.date_released] = audiobook
          end
        end
      end
    end

    def <=>(other)
      return self.id <=> other.id
    end

    def to_s()
      return self.id
    end
  end
end
