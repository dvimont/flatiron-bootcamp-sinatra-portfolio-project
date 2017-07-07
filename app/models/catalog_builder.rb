require 'open-uri'
require 'json'
require 'nokogiri'

class CatalogBuilder

  LIBRIVOX_API_URL = "https://librivox.org/api/feed/audiobooks/"
  LIBRIVOX_API_PARMS = "?fields={id,url_librivox,language}&format=json"
  DEFAULT_CATALOG_SIZE = 12000
  LIMIT_PER_CALL = 50
  LOCAL_API_RESPONSE_URI_PREFIX = "./public/api_responses/"
  # NOTE: It is intentional that there is no special processing option to force a
  #    "full refresh" of all local files. This is to prevent accidental submission
  #    of such an option, which can (depending upon the time of day) almost constitute
  #    the equivalent of a "denial of service attack" on the Librivox server.
  #  To intentionally do a full refresh of the local API and webpage files, simply
  #    rename the appropriate subdirectories in the "./public" directory, create
  #    new empty directories in their places, and run with :remote_api_calls option.
  # NOTE also that the tar file containing Gutenberg collection information
  #    (via which GenreGutenberg category classes are derived) may need
  #    to periodically be manually refreshed via download from Gutenberg
  #    (see http://www.gutenberg.org/feeds/):
  #    The file should be manually unzipped, rezipped in gzip format, and placed in the
  #    .public/web_pages/gutenberg directory to replace the "rdf-files.tar.gz" file.
  VALID_SPECIAL_PROCESSING_OPTIONS = [
    :local_uri_calls, # forces all API calls and all webpage lookups to be done against local files
    :local_api_calls, # all API calls done against local files;
                        # webpage lookups initially done against local zip files
                        #  ==>> if webpage not found locally,
                        #         remote lookup done and result zipped/persisted locally
    :remote_api_calls # Librivox API calls done remotely via http: calls (which may find new audiobooks)
                        # webpage lookups initially done against local zip files
                        #  ==>> if webpage not found locally,
                        #         remote lookup done and result zipped/persisted locally
  ]
  @@special_processing_parm = :local_uri_calls

  def self.default_catalog_size
    return DEFAULT_CATALOG_SIZE
  end

  def self.build(catalog_size=DEFAULT_CATALOG_SIZE, special_processing=:local_uri_calls, optional_parms="")
    if !VALID_SPECIAL_PROCESSING_OPTIONS.include?(special_processing)
      raise ArgumentError, "Invalid special_processing argument submitted: <#{special_processing.to_s}>.  " +
          "Valid options are: #{VALID_SPECIAL_PROCESSING_OPTIONS.to_s}"
    end
    @@special_processing = special_processing
    offset = 0
    records_remaining_to_fetch = catalog_size
    build_timer = Timer.new
    api_timer = Timer.new

    puts "****** BUILDING CATALOG OF AUDIOBOOKS! ****** #{self.current_time}"
    puts "*** Starting API calls and Audiobook initialization"
    while records_remaining_to_fetch > 0
      call_limit = (records_remaining_to_fetch > LIMIT_PER_CALL) ?
                            LIMIT_PER_CALL : records_remaining_to_fetch
      records_remaining_to_fetch -= call_limit

      begin
        api_parms = LIBRIVOX_API_PARMS +
            "&offset=" + offset.to_s + "&limit=" + call_limit.to_s + optional_parms
        if @@special_processing != :local_api_calls && @@special_processing != :local_uri_calls
          puts "** Called API for #{call_limit.to_s} records at offset #{offset.to_s}: " + current_time

          open(get_local_uri(api_parms), "wb") { |file|
            open(LIBRIVOX_API_URL + api_parms, :read_timeout=>nil) { |uri|
               file.write(uri.read)
            }
          }
        end

        api_result = open(get_local_uri(api_parms), :read_timeout=>nil)

      rescue OpenURI::HTTPError => ex
        if ex.to_s.start_with?("404")
          puts "** HTTP 404 response from Librivox API; apparent end of catalog has been reached! **"
        else
          puts "** Error returned by OpenURI during call to Librivox API. Error message is as follows:"
        end
        puts ex.to_s
        puts "====="
        break
      end
      offset += call_limit
      # puts "** Call to API completed: " + current_time
      json_string = api_result.read
      if json_string.empty? && (@@special_processing == :local_api_calls || @@special_processing == :local_uri_calls)
        puts "***    Apparent end of catalog has been reached while using :local_*_calls special_processing option! **"
        break
      end
      returned_hash = JSON.parse(json_string,{symbolize_names: true})
      hash_array = returned_hash.values[0]
      Audiobook.mass_initialize(hash_array)
    end
    puts "***    API calls and Audiobooks initialization completed in #{api_timer.how_long?}"

    if @@special_processing == :convert_to_zip
      Audiobook.all.each{ |audiobook|
        ScraperLibrivox.convert_to_zip(audiobook.url_librivox)
      }
      return
    end

    self.scrape_webpages
    self.build_category_objects
    self.build_solo_group_hashes # must come after Reader category objects instantiated

    puts "****** FULL BUILD OF CATALOG OF #{Audiobook.all.size.to_s} AUDIOBOOKS COMPLETED IN #{build_timer.how_long?} " +
        "****** #{self.current_time}"

    return :successful_build
  end

  def self.scrape_webpages
    puts "*** Starting scraping of #{Audiobook.all.size.to_s} Librivox webpages"
    scrape_timer = Timer.new
    progress_counter = 0
    apparent_works_in_progress = SortedSet.new
    Audiobook.all.each{ |audiobook|
      attributes_hash = ScraperLibrivox.get_audiobook_attributes_hash(
                              audiobook.url_librivox, @@special_processing)
      if attributes_hash.nil?
        apparent_works_in_progress.add(audiobook)
      else
        audiobook.add_attributes(attributes_hash)
      end
      # progress_counter += 1
      # if (progress_counter % 100 == 0)
      #   puts "   -- scraping completed for #{progress_counter.to_s} audiobooks -- "  + current_time
      # end
    }
    apparent_works_in_progress.each{|audiobook|
      Audiobook.all.delete(audiobook)
      Audiobook.works_in_progress.add(audiobook)
    }
    puts "***    Scraping of #{Audiobook.all.size.to_s} Librivox webpages completed in: #{scrape_timer.how_long?}"

    puts "*** Starting scraping of Gutenberg repository"
    scrape_timer = Timer.new
    ScraperGutenberg.process_gutenberg_genres
    puts "***    Scraping of Gutenberg repository completed in: #{scrape_timer.how_long?}"
  end

  def self.build_category_objects
    puts "*** Starting initialization of Categories for #{Audiobook.all.size.to_s} audiobooks"
    category_timer = Timer.new
    progress_counter = 0
    Audiobook.all.each{ |audiobook|
      next if audiobook.title.nil?
      audiobook.build_category_objects
      # progress_counter += 1
      # if (progress_counter % 100 == 0)
      #   puts "   -- build of categories completed for #{progress_counter.to_s} audiobooks -- " + current_time
      # end
    }
    puts "***    Initialization of Categories completed in: #{category_timer.how_long?}"
  end

  def self.build_solo_group_hashes
    puts "*** Starting Solo/Group categorization for #{Audiobook.all.size.to_s} audiobooks"
    solo_group_timer = Timer.new
    Audiobook.all.each{ |audiobook|
      audiobook.build_solo_group_hashes
    }
    puts "***    Solo/Group categorization completed in: #{solo_group_timer.how_long?}"
  end

  def self.current_time
    current_time = Time.now.to_s
    current_time = current_time.slice(0,current_time.length - 6)
    return current_time
  end

  def self.get_local_uri(api_parms)
    return LOCAL_API_RESPONSE_URI_PREFIX + api_parms
  end

end

class Timer

  def initialize
    @start_time = Time.now.to_f
  end

  def how_long?
    total_seconds_float = Time.now.to_f - @start_time
    total_seconds = total_seconds_float.to_i
    hundredths_of_second = (((total_seconds_float - total_seconds).round(2)) * 100).to_i
    less_than = ""
    if hundredths_of_second == 0 && total_seconds == 0
      hundredths_of_second = 1 if hundredths_of_second == 0 && total_seconds == 0
      less_than = "< "
    end

    return less_than + "#{(total_seconds / 60).to_s}:#{"%02d"%(total_seconds % 60).to_s}" +
                      ".#{"%02d"%(hundredths_of_second).to_s}"
  end

end
