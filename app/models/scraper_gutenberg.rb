require 'nokogiri'
require 'zip'

# NOTE: This process utiizes a tar file provided by Project Gutenberg,
#   provided to obviate the need for external agents to pound their website
#   with robotic scraping "attacks". The process involves opening the tar
#   file and looping through its file directory looking for a matching
#   audibook in the Audiobook.all_by_gutenberg_id collection. When a match
#   is found, the current Gutenberg file is opened with the Nokogiri parser,
#   and its subject (i.e. genre) data is extracted and passed to the audiobook.

# TO DO: The "rdf-files.tar.gz" file used here should be automatically
#   intermittently downloaded from the Gutenberg site
#   (https://www.gutenberg.org/cache/epub/feeds/rdf-files.tar.zip)
#   and unzipped to extract the tar file, and then rezipped in "gz" (gzip) format.
#   Currently, this is being done manually.

class ScraperGutenberg
  LOCAL_WEBPAGE_URI_PREFIX = "./public/web_pages/"
  GUTENBERG_TAR_FILE = "gutenberg/rdf-files.tar.gz"
  GUTENBERG_TAR_PATH = LOCAL_WEBPAGE_URI_PREFIX + GUTENBERG_TAR_FILE

  class << self
    def process_gutenberg_genres()
      Zlib::GzipReader.open(GUTENBERG_TAR_PATH) { |tgz|
        Archive::Tar::Minitar::Reader.open(tgz).each { |entry|
        # Minitar::Input.open(GUTENBERG_TAR_PATH).each { |entry|
          gutenberg_id = entry.name[/\/\d+\//].delete("/")
          matched_audiobook = Audiobook.all_by_gutenberg_id[gutenberg_id]
          if matched_audiobook
            gutenberg_xml = Nokogiri::XML(entry)
            subject_elements = gutenberg_xml.css(
                "rdf|RDF pgterms|ebook dcterms|subject rdf|Description rdf|value")
            gutenberg_subjects = Array.new
            subject_elements.each{|subject|
              gutenberg_subjects.push(subject.text) if !subject.text[/^[A-Z][A-Z]?$/]
            }
            if !gutenberg_subjects.empty?
              matched_audiobook.gutenberg_subjects = gutenberg_subjects
            end
          end
        }
      }
    end
  end

end
