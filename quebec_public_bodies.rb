# coding: utf-8
# @todo Properly case the organization name and rename the tag.
# @todo Use the same headers as Alaveteli.

# @note Requires Ruby 1.9 and Rails 3.x.

require 'csv'
require 'active_support/inflector'

if ARGV.include?('--clobber') || !File.exist?('CAI_liste_resp_acces.pdf')
  `curl -O http://www.cai.gouv.qc.ca/documents/CAI_liste_resp_acces.pdf`
end

block   = []
block_1 = nil
block_2 = nil
tag     = nil
ignore  = /\A(Dernière mise à jour : \d{4}-\d{2}-\d{2} \d{2}:\d{2}|Page \d+|Répertoire des organismes assujettis et des responsables de l'accès aux documents des organismes publics et de la protection des renseignements personnels)\z/

# Finds the element in the array that matches the regular expression, removes
# that element from the array, and returns the first capturing group matched by
# the regular expression.
#
# @param [Array] array an array
# @param [Regexp] regexp a regular expression
# @return [String] the first capturing group
def find_and_delete(array, regexp)
  index = array.index{|x| x[regexp]}
  index && array.delete_at(index)[regexp, 1]
end

organizations = []
`pdftotext CAI_liste_resp_acces.pdf -`.split("\n").each do |line|
  line.strip!

  # Collect a block, then parse it.
  if line.empty?
    text = block * ' '
    unless text.empty? || text[ignore]
      # The first block is the table of contents.
      if block_1.nil?
        block_1 = block
      # The second block is the page numbers for the table of contents.
      elsif block_2.nil?
        block_2 = block
      else
        # The first line of a block is sometimes an item from the table of contents.
        if block_1.include?(block.first)
          tag = block.first
          block.shift
        end

        organization = {
          organization: [],
          name: nil,
          role: [],
          address: [],
          voice: find_and_delete(block, /\ATél\. : ([\d# -]+)\z/),
          fax: find_and_delete(block, /\ATéléc\. : ([\d# -]+)\z/),
          tollfree: find_and_delete(block, /\ASans frais : ([\d -]+)\z/),
          email: find_and_delete(block, /\A(\S+@\S+)\z/),
          tag: tag,
        }

        block.each_with_index do |x,index|
          # Ensure that organizations are read before names, and roles before
          # addresses. Addresses swallow whatever is left.
          if organization[:name].nil?
            if x[/\A[\p{Lu}\p{Punct}\p{Space}]+\z/]
              organization[:organization] << x
            else
              organization[:name] = x
            end
          elsif organization[:address].empty?
            if x[/\A\d|\bC\.P\. /]
              organization[:address] << x
            else
              organization[:role] << x
            end
          else
            organization[:address] << x
          end
        end

        organization[:organization] *= ' '
        organization[:role] *= ' '
        organization[:address] *= ' '
        organizations << organization
      end
    end
    block = []
  else
    block << line
  end
end

# Alaveteli does not support multiple contacts per public body.
safe = organizations.uniq do |x|
  ActiveSupport::Inflector.parameterize(x[:organization])
end

puts "%4d organizations" % organizations.size
puts "%4d voice" % organizations.count{|x| x[:voice]}
puts "%4d fax" % organizations.count{|x| x[:fax]}
puts "%4d email" % organizations.count{|x| x[:email]}
puts "%4d safe" % safe.size

CSV.open('organizations.csv', 'w') do |csv|
  csv << organizations.first.keys
  organizations.each do |organization|
    csv << organization.values
  end
end

CSV.open('organizations-alaveteli-safe.csv', 'w') do |csv|
  csv << safe.first.keys
  safe.each do |organization|
    csv << organization.values
  end
end
