require 'csv'

require 'pupa'
require 'vcard'

# @see http://www.bt-tb.tpsgc-pwgsc.gc.ca/btb.php?lang=eng&cont=044
def tel(string)
  string.to_s.gsub(/\D/, '').sub(/\A(\d{3})(\d{3})(\d{4})\z/, '\1-\2-\3')
end

class OrganizationProcessor < Pupa::Processor
  def names
    @names ||= begin
      names = {}
      CSV.foreach(File.expand_path(File.join('data', 'ca_provinces_and_territories.csv'), __dir__)) do |identifier,name|
        names[identifier.sub('division', 'organization')] = name
      end
      names
    end
  end
end

OrganizationProcessor.add_scraping_task(:organizations)
