## NOTE: This Hash wrapper efficiently finds and returns values
##  (via the #[] method) through encapsulated use of the Array#bsearch method
##  against an internally maintained sorted key-value array.
##
##  It is intended for situations in which efficiency of lookups is paramount,
##  but where efficiency in adding values and building the initial Hash is less
##  important.

class HashWithBsearch

  def initialize(sort_option=:ascending)
    result = (@wrapped_hash = Hash.new)
    @sort_option = sort_option
    @sorted_hash = Hash.new
    if @sort_option == :descending
      @sort_block = proc {|a,b| b<=>a}
    else
      @sort_block = proc {|a,b| a<=>b}
    end
    sync_sorted_array_and_hash   # utilizes @sort_block
    return result
  end

  def size()
    return @sorted_key_value_array.size
  end

  # GETTER METHODS
  def [](key)
    rebuild_sorted_hash
    if @sorted_key_value_array.empty?
      return nil
    else
      if @sort_option == :descending
        found_kv_pair = @sorted_key_value_array.bsearch{|kv_pair| kv_pair[0] <=> key}
      else
        found_kv_pair = @sorted_key_value_array.bsearch{|kv_pair| key <=> kv_pair[0]}
      end
      return (found_kv_pair == nil) ? nil : found_kv_pair[1]
    end
  end

  def each(&block)
    rebuild_sorted_hash
    if block_given?
      return @sorted_hash.each &block
    else
      return @sorted_hash.each
    end
  end

  def select(&block)
    rebuild_sorted_hash
    return @sorted_hash.select &block
  end

  # Intended to provide O(log n) efficiency when searching for an ordered
  #  subset of items that match the submitted <key_prefix> argument.
  # EXAMPLE: authors_keyed_by_name.key_starts_with("M") would return an array
  #          of values for all authors whose key begins with "M".
  def values_with_key_prefix(key_prefix)
    start_index = @sorted_key_value_array.bsearch_index{ |kv_pair|
                    kv_pair[0][0,key_prefix.length] >= key_prefix }
    return []  if start_index.nil?

    end_index = @sorted_key_value_array.bsearch_index{ |kv_pair|
                    kv_pair[0][0,key_prefix.length] > key_prefix}
    if end_index.nil? # end of array was reached
      end_index = @sorted_key_value_array.size - 1
    else
      end_index -= 1
    end

    return []  if end_index < start_index # i.e. if key_prefix not found!
    return @sorted_key_value_array[start_index..end_index].collect{|kv_pair| kv_pair[1]}
  end

  def values_with_nonroman_key()
    non_roman_array = Array.new

    first_A_index = @sorted_key_value_array.bsearch_index{|kv_pair| kv_pair[0][0] >= 'A' }
    first_past_z_index = @sorted_key_value_array.bsearch_index{|kv_pair| kv_pair[0][0] > 'z' }
    if !first_A_index.nil? && first_A_index > 0
      non_roman_array = @sorted_key_value_array[0..(first_A_index - 1)]
    end
    if !first_past_z_index.nil?
      non_roman_array.concat(
          @sorted_key_value_array[first_past_z_index..(@sorted_key_value_array.size - 1)])
    end

    return non_roman_array.collect{|kv_pair| kv_pair[1]}
  end

  def keys
    rebuild_sorted_hash
    return @sorted_hash.keys
  end

  def values
    rebuild_sorted_hash
    return @sorted_hash.values
  end

  # SETTER METHODS -- additional methods may need to be added!
  def []=(key, value)
    @wrapped_hash[key] = value
    sync_sorted_array_and_hash([key, value])
  end

  # NOTE: #shift, #clear, and all other standard deletion methods (#pop, etc.) have
  #  not yet been properly coded, as they were not needed by the original application.
  #  Ultimately, the @wrapped_hash variable should be done away with, and all
  #  operations should go against @sorted_key_value_array
  def shift()
    result = @wrapped_hash.shift
    sync_sorted_array_and_hash
    return result
  end

  def clear()
    result = @wrapped_hash.clear
    sync_sorted_array_and_hash
    return result
  end

  private

  def rebuild_sorted_hash
    if @sorted_hash.nil?
      @sorted_hash = @sorted_key_value_array.to_h
    end
  end

  def sync_sorted_array_and_hash(inserted_kv_pair=nil)
    if @wrapped_hash.size == 0
      @sorted_key_value_array = Array.new
      @sorted_hash = Hash.new
    else
      if inserted_kv_pair.nil?
        @sorted_key_value_array = @wrapped_hash.sort &@sort_block
      else
        if @sort_option == :descending
          insertion_index = @sorted_key_value_array.bsearch_index{|kv_pair| inserted_kv_pair[0] >= kv_pair[0]}
        else
          insertion_index = @sorted_key_value_array.bsearch_index{|kv_pair| kv_pair[0] >= inserted_kv_pair[0]}
        end
        if insertion_index.nil?
          @sorted_key_value_array.push(inserted_kv_pair)
        else
          @sorted_key_value_array.insert(insertion_index, inserted_kv_pair)
        end
      end
      @sorted_hash = nil # forces rebuild of @sorted_hash upon next invocation of a getter method
    end
  end
end
