require 'bundler/setup'

require 'csv'

require 'govkit-ca'
require 'pupa'
require 'vcard'

module OrganizationHelper
  POSTAL_CODE_RE = /\b[A-Z]\d[A-Z]\s*\d[A-Z]\d\b/

  # @see http://www.bt-tb.tpsgc-pwgsc.gc.ca/btb.php?lang=eng&cont=044
  def tel(string)
    string.to_s.gsub(/\D/, '').sub(/\A(\d{3})(\d{3})(\d{4})\z/, '\1-\2-\3')
  end

  # @see http://www.canadapost.ca/tools/pg/manual/PGaddress-e.asp#1417000
  def adr(string)
    string.to_s.strip.sub(/[\s,]+(AB|BC|MB|ON|NB|NL|NS|NT|NU|PE|QC|SK|YT)[\s,]+(#{POSTAL_CODE_RE})\z/, ' \1  \2')
  end

  def valid_postal_code?(string)
    GovKit::CA::PostalCode.valid?(GovKit::CA::PostalCode.format_postal_code(string.to_s[POSTAL_CODE_RE]))
  end
end

class OrganizationProcessor < Pupa::Processor
  include OrganizationHelper

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
