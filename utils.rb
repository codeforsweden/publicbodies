require 'csv'

require 'pupa'

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
