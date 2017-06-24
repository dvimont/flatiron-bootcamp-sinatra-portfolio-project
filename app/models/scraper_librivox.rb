require 'json'
require 'nokogiri'
require 'zip'

class ScraperLibrivox
  LOCAL_WEBPAGE_URI_PREFIX = "./public/web_pages/"
  LIBRIVOX_DOMAIN = "librivox.org/"
  LOCAL_WEBPAGE_URI_PATH = LOCAL_WEBPAGE_URI_PREFIX + LIBRIVOX_DOMAIN
  HTML_FILE_SUFFIX = ".html"
  LOCAL_ZIP_FILE_SUFFIX = HTML_FILE_SUFFIX + ".zip"

  class << self
    def get_audiobook_attributes_hash(url_librivox, special_processing=:none)
      attributes = Hash.new
      begin
        if url_librivox.start_with?("http:")
          url_librivox = "https" + url_librivox[4,url_librivox.length]
        end
        if special_processing != :local_uri_calls
          retrieve_and_persist_http_response(url_librivox)
        end

        page_content = get_local_page_content(url_librivox)
        return if page_content.nil?

        book_page_section = page_content.css("div.main-content div.page.book-page")
        if book_page_section.nil? || book_page_section.size == 0
          return attributes
        end
        book_page_sidebar_section = page_content.css(
                "div.main-content div.sidebar.book-page div.book-page-sidebar")

        # SCRAPE: title, genre, and url_cover_art
        title_genre_section = book_page_section.css("div.content-wrap")
        title_element = title_genre_section.css("h1")[0]
        if title_element
          attributes[:title] = title_genre_section.css("h1")[0].text
        else
          puts "  -- no title found for audiobook at url: " + url_librivox
          attributes[:title] = "NO TITLE: " + url_librivox
        end

        genre_elements = title_genre_section.css("p.book-page-genre")
        genre_elements.each{ |element|
          if element.css("span").text == "Genre(s):"
            attributes[:genres_csv_string] = element.text[10, element.text.length]
            break
          end
        }

        cover_art_img_element = title_genre_section.css("div.book-page-book-cover img")
        if cover_art_img_element
          attributes[:url_cover_art] = cover_art_img_element.attribute("src").value
        end

        # SCRAPE: date-released from sidebar section
        product_details = book_page_sidebar_section.css("dl.product-details *")
        previous_text = ""
        product_details.each {|element|
          if previous_text == "Catalog date:"
            attributes[:date_released] = element.text
            break
          end
          previous_text = element.text
        }

        # SCRAPE: url_text from sidebar section
        links = book_page_sidebar_section.css("p a")
        links.each {|element|
          if element.text.upcase[/.*ONLINE TEXT.*/]
            url_text = element.attribute("href").value
            attributes[:url_text] = url_text
            if url_text[/gutenberg.org\/etext\/\d+$/]
              attributes[:gutenberg_id] = url_text[/\d+$/]
            end
          elsif element.text.upcase[/.*INTERNET ARCHIVE PAGE.*/]
            attributes[:url_iarchive] = element.attribute("href").value
          end
        }

        readers_hash = extract_contributors_hash(book_page_section, "reader")
        if !readers_hash.empty?
          attributes[:readers_hash] = readers_hash
        end

        authors_hash = extract_contributors_hash(book_page_section, "author")
        if !authors_hash.empty?
          attributes[:authors_hash] = authors_hash
        end

      rescue OpenURI::HTTPError => ex
        attributes[:http_error] = ex.to_s
      end

      return attributes
    end

    # NOTE: author & reader (contributor) "a" elements contain
    #   (1) href attribute with url that ends with author-id or reader-id, and
    #   (2) value containing author's or reader's displayable name and
    #       OPTIONAL (birth-death) designation.
    #   The hash returned by this method contains entries like:
    #     {"110" => "Cynthia Lyons (1946-2011)"}
    def extract_contributors_hash(book_page_section, contributor_type)
      contributors_hash = Hash.new
      # Author's and Reader's "a" elements are placed in varying locations, but their
      #   structure is always identifiable by the following wildcard css search.
      contributor_elements = book_page_section.css('a[href*="/' + contributor_type + '/"]')
      if contributor_elements
        contributor_elements.each{ |contributor_element|
          contributor_id = contributor_element.attribute("href").value[/\d+$/]
          contributor_text = contributor_element.text
          if contributor_id && contributor_text
            contributors_hash[contributor_id] = contributor_text
          end
        }
      end
      return contributors_hash
    end

    def retrieve_and_persist_http_response(url)
      local_file_metadata = get_local_file_metadata(url)

      # if webpage already stored locally, nothing need be done
      if File.file?(local_file_metadata[0])
        return
      end
      # assure no "redirect" is occurring with librivox page (works in progress often redirect)
      open(url, {:read_timeout=>nil, :redirect=>false}) { |uri| return if uri.read.empty? }

      puts "***    Persisting file locally for: #{local_file_metadata[1]}" # " in #{local_file_metadata[0]}"
      Zip::File.open(local_file_metadata[0], Zip::File::CREATE) { |zipfile|
        open(url, {:read_timeout=>nil, :redirect=>false}) { |uri|
          zipfile.get_output_stream(local_file_metadata[1]) { |f| f.puts uri.read }
        }
      }
    end

    def get_local_page_content(url)
      local_file_metadata = get_local_file_metadata(url)
      if !File.file?(local_file_metadata[0])
        return nil
      end
      Zip::File.open(local_file_metadata[0]) { |zipfile|
        return Nokogiri::HTML(zipfile.read(local_file_metadata[1]))
      }
    end

    def get_local_file_metadata(url)
      url_prefix = url[/https?:\/\/librivox.org\//]
      return nil if url_prefix.nil?

      substring_length = url.length - url_prefix.length
      substring_length -= 1 if url.end_with?("/")
      page_identifier = url[url_prefix.length,substring_length]
      zip_file_uri = LOCAL_WEBPAGE_URI_PATH + page_identifier + LOCAL_ZIP_FILE_SUFFIX
      html_file_name = page_identifier + HTML_FILE_SUFFIX
      return [zip_file_uri, html_file_name]
    end

#    ZIP_FILETYPE = ".zip"
#    ZIP_SUBDIR = "zips/"
#    def convert_to_zip(url_librivox)  # file, path)
#      local_uri = get_local_uri(url_librivox)
#      html_filename = get_local_file_metadata(url_librivox)[1] # second element is html file-name
#      zipfile = LOCAL_WEBPAGE_URI_PATH + ZIP_SUBDIR + html_filename + ZIP_FILETYPE
#      if !File.file?(local_uri)
#        puts "LOCAL FILE NOT FOUND; SKIPPING: " + local_uri
#        return
#      end
#      if File.file?(zipfile)
#        puts "ZIPFILE ALREADY EXISTS: " + zipfile
#      else
#        puts "CONVERTING FOLLOWING TO ZIP: " + local_uri
#        Zip::File.open(zipfile, Zip::File::CREATE) { |zipfile|  zipfile.add(html_filename, local_uri) }
#        puts "ZIPFILE CREATED: " + zipfile
#      end
#    end
  end
end
