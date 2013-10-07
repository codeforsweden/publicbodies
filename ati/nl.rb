require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class NL < OrganizationProcessor
  self.jurisdiction_code = 'CA-NL'

  URL = 'http://www.atipp.gov.nl.ca/info/coordinators.html'

  def scrape_organizations
  end
end

run(NL)