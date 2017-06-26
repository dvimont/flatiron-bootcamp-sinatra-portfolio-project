class Contributor
  include Category::InstanceMethods

  @@SUBCATEGORIZABLE = true

#  def self.all_by_name
    #  this method implemented only in subclasses
#  end

  def self.mass_initialize(hash)
    contributors = Array.new
    # NOTE: contributors hash can look like this:
    #  {"431"=>"Alexandre DUMAS (1802 - 1870)", "221"=>" UNKNOWN ( - )"}
    hash.each{ |id, contributor_data_string|
      if id.nil? # dirty data has likely been scraped from a webpage
        next
      end
      attributes = Hash.new
      name_date_pair = contributor_data_string.split("(")
      if name_date_pair[0] != nil
        name_date_pair[0].strip!
        name_components = name_date_pair[0].strip.split
        if name_components != nil && name_components.size > 0
          attributes[:last_name] = name_components.pop
          if name_components.size > 0
            attributes[:first_name] = name_components.join(" ")
          end
        end
      end
      if !name_date_pair[1].nil? && name_date_pair[1].match(/^\d{4}/)
        years = name_date_pair[1].strip.delete!(")").split(" - ")
        if years[0] != nil && !years[0].empty? && years[0].length >= 4
          attributes[:birth_year] = years[0]
        end
        if years[1] != nil && !years[1].empty? && years[1].length >= 4
          attributes[:death_year] = years[1]
        end
      end
      contributor_object = self.create_or_get_existing(id, attributes)
      # Some contributor_data_string scrapes do not include date info
      #   Add such data from current contributor_data_string if
      #   contributor_object doesn't currently have it.
      if (contributor_object.birth_year.nil? || contributor_object.birth_year == "") &&
            !attributes[:birth_year].nil? && !attributes[:birth_year].empty?
        contributor_object.add_attributes({birth_year: attributes[:birth_year]})
      end
      if (contributor_object.death_year.nil? || contributor_object.death_year == "") &&
            !attributes[:death_year].nil? && !attributes[:death_year].empty?
        contributor_object.add_attributes({birth_year: attributes[:birth_year]})
      end
      contributors.push(contributor_object)
    }
    return contributors
  end

  attr_accessor :last_name, :first_name, :birth_year, :death_year

  def add_self_to_class_collections()
    super
    if self.first_name.nil?
      name_key = self.last_name
    else
      last_name_upcase = self.last_name.to_s.upcase
      ## NOTE: It is possible that more last_name_upcase comparisons will need to be added here.
      if last_name_upcase == "VERSION" || last_name_upcase == "VULGATA" ||
          last_name_upcase == "COMPANY" || last_name_upcase == "CONGRESS" ||
          ('0'..'9').include?(self.last_name.to_s[0])
        name_key = self.first_name.to_s + " " + self.last_name.to_s
      else
        name_key = self.last_name.to_s +
                    ("_" * (30 - self.last_name.length)) + self.first_name.to_s
      end
    end
    self.class.all_by_name[name_key.upcase] = self  if !name_key.nil?
  end

  def to_s()
    returned_string = ""
    returned_string += self.first_name + " "  if !self.first_name.nil?
    returned_string += self.last_name
    if (!self.birth_year.nil? && !self.birth_year.empty?) ||
          (!self.death_year.nil? && !self.death_year.empty?)
      returned_string += " (#{self.birth_year}-#{self.death_year})"
    end
    return returned_string
  end
end
