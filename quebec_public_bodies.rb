#!/usr/bin/env ruby
# coding: utf-8

require 'csv'

if ARGV.include?('--clobber') || !File.exist?('CAI_liste_resp_acces.pdf')
  `curl -O http://www.cai.gouv.qc.ca/documents/CAI_liste_resp_acces.pdf`
end

# Finds the element in the array that matches the regular expression, removes
# that element from the array, and returns the first capturing group matched by
# the regular expression.
#
# @param [Array] array an array
# @param [Regexp] regexp a regular expression
# @return [String] the first capturing group
def find_and_delete(array, regexp)
  index = array.index{|x| x[regexp]}
  if index
    value = array.delete_at(index)[regexp, 1]
    if array[index - 1][/-\z/]
      array.delete_at(index - 1) + value
    elsif value[/-\z/]
      value + array.delete_at(index)
    else
      value
    end
  end
end

# @param [String] string a string
# @return [Boolean] whether the string is all-caps
def header?(string)
  !!(string[/\A[\p{Lu}\p{N}\p{Punct}\p{Space}]+\z/] && !string[/\A(C\.P\. [\d-]+|[\d, ]+|([A-Z]\d[A-Z] )?\d[A-Z]\d)\z/])
end

# @param [Array<String>] strings an array of strings
# @return [String] the combined string
def join(strings)
  output = strings.shift || ''
  strings.each do |string|
    if output[/-\z/]
      output += string
    else
      output += ' ' + string
    end
  end
  output
end

ignore = /\A(Dernière mise à jour : \d{4}-\d{2}-\d{2} \d{2}:\d{2}|Page \d+|Répertoire des organismes assujettis et des responsables de l'accès aux documents des organismes publics et de la protection des renseignements personnels)\z/

# Alternatively, we can hardcode the table of contents and skip this step.
table_of_contents = nil
block = []
`pdftotext CAI_liste_resp_acces.pdf -`.split("\n").each do |line|
  line.strip!

  # Collect a block, then parse it.
  if line.empty?
    text = block * ' '
    unless text.empty? || text[ignore]
      table_of_contents = block
      break
    end
    block = []
  else
    block << line
  end
end

ignore = /\A(Dernière mise à jour : \d{4}-\d{2}-\d{2} \d{2}:\d{2} Page \d+|Répertoire des organismes assujettis et des|responsables de l'accès aux documents des|organismes publics et de la protection des|renseignements personnels)\z/
ready = false
in_header = true
type = nil

# pdftotext incorrectly removes hyphens at line endings. The -raw switch keeps
# line endings, but is harder to parse.
organizations = []
block = []
`pdftotext -raw CAI_liste_resp_acces.pdf -`.split("\n").each do |line|
  line.strip!

  # Skip lines until we find the first page of public bodies.
  unless ready
    if line == table_of_contents.first
      ready = true
    else
      next
    end
  end

  next if line[ignore]

  # Collect a block, then parse it.
  if !in_header && header?(line)
    unless block.empty?
      # The first line of a block is sometimes an item from the table of contents.
      if table_of_contents.include?(block.first)
        type = block.shift
      end

      organization = {
        :organization => [], # Alaveteli
        :name         => nil,
        :role         => [],
        :address      => [],
        :voice        => find_and_delete(block, /\ATél\. : ([\d# -]+)\z/),
        :fax          => find_and_delete(block, /\ATéléc\. : ([\d# -]+)\z/),
        :tollfree     => find_and_delete(block, /\ASans frais : ([\d -]+)\z/),
        :email        => find_and_delete(block, /\A(\S+@\S+)\z/), # Alaveteli
        :type         => type, # tags
      }

      block.each_with_index do |x,index|
        # Ensure that organizations are read before names, and roles before
        # addresses. Addresses swallow whatever is left.
        if organization[:name].nil?
          if header?(x)
            # @todo Properly case the organization name.
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

      organization[:organization] = join(organization[:organization])
      organization[:role] = join(organization[:role])
      organization[:address] = join(organization[:address])

      unless organization[:address][/\b[A-Z]\d[A-Z] \d[A-Z]\d\z/]
        puts "Invalid address: #{organization.inspect}"
      end

      organizations << organization
    end

    in_header = true
    block = [line]
  else
    in_header = false unless header?(line)
    block << line
  end
end

# Alaveteli does not support multiple contacts per public body.
unique = []
organizations.group_by{|x| x[:organization]}.each do |_,organizations|
  # Select the contact with an email address.
  unique << (organizations.find{|x| x[:email]} || organizations.first)
end

headers = organizations.first.keys
size = organizations.size.to_f

puts "%4d organizations" % size
headers.each do |header|
  puts "%5.1f%% #{header}" % (organizations.count{|x| x[header.to_sym]} / size * 100)
end
puts "%5.1f%% unique" % (unique.size / size * 100)



CSV.open('organizations.csv', 'w') do |csv|
  csv << headers
  organizations.each do |organization|
    csv << organization.values
  end
end

# @todo Fill in tags. Get a list of categories from WhatDoTheyKnow.com for
#   inspiration, and get an expert on Quebec government (ask Mathieu?).
tags = {
  "AGENCES DE LA SANTÉ"                           => ['santé'],
  "AUTRES ORGANISMES GOUVERNEMENTAUX"             => [],
  "CÉGEPS"                                        => ['éducation'],
  "CENTRE DE COMMUNICATIONS SANTÉ (911)"          => ['santé'],
  "CENTRE DE SANTÉ ET DE SERVICES SOCIAUX (CSSS)" => ['santé'],
  "CENTRES D'HÉBERGEMENT ET DE RÉADAPTATION"      => [],
  "CENTRES HOSPITALIERS"                          => ['santé'],
  "CENTRES JEUNESSE"                              => ['jeunesse'],
  "COMMISSIONS SCOLAIRES"                         => ['éducation'],
  "ÉTABLISSEMENTS PRIVÉS SUBVENTIONNÉS"           => ['éducation'],
  "MINISTÈRES"                                    => [],
  "MUNICIPALITÉS"                                 => ['municipalités'],
  "MUNICIPALITÉS RÉGIONALES DE COMTÉ (MRC)"       => ['municipalités'],
  "OFFICES MUNICIPAUX D'HABITATION"               => [],
  "ORDRES PROFESSIONNELS"                         => [],
  "ORGANISMES MUNICIPAUX"                         => [],
  "RÉGIES INTERMUNICIPALES"                       => [],
  "UNIVERSITÉS"                                   => ['éducation'],
}

CSV.open('organizations-for-alateveli.csv', 'w') do |csv|
  # Translatable fields:
  #
  # * `name`: The public body's name. Required.
  # * `short_name`: An alternative name for the public body, often an acronym.
  # * `request_email`: The public body's email address.
  # * `notes`: Helpful HTML notes for requesters about the public body.
  # * `publication_scheme`: The URL of the public body's publication scheme,
  #   which describes what information the public body publishes proactively.
  #
  # To localize a field, add a locale string to the field name, e.g. `name.es`.
  #
  # Other fields:
  #
  # * `disclosure_log`: The URL of the public body's disclosure log, which may
  #   be a subset of responses to previous requests.
  # * `home_page`: The public body's URL.
  # * `tag_string`: A list of tags to categorize the public body.
  csv << %w(#id name request_email tag_string notes)
  unique.each do |organization|
    # @todo Put instructions on how to contact the public body by mail in the
    #   notes section. Change text slightly for public bodies without email.
    csv << [
      '',
      organization[:organization],
      organization[:email],
      tags.fetch(organization[:type]) * ' '
    ]
  end
end

CSV.open('quebec.csv', 'w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)
  
  organizations.each do |organization|
    csv << [
      organization[:organization],                          #title
      '',                                                   #abbr
      'qc/' << organization[:organization].gsub(' ','-'),   #key
      organization[:type],                                  #category
      '',                                                   #parent
      '',                                                   #parent_key
      '',                                                   #description
      '',                                                   #url
      'Quebec',                                             #jurisdiction
      'QC',                                                 #jurisdiction_code
      "Commision d'accès à l'information du Québec",        #source
      'http://www.cai.gouv.qc.ca/documents/CAI_liste_resp_acces.pdf', #source_url
      organization[:address],                               #address
      organization[:name],                                  #contact
      organization[:email],                                 #email
      '',                                                   #tags
      '5/17/13',                                            #created at
      Date.today.strftime('%-m/%-d/%y')                         #updated at
    ]  
  end  
  
end
