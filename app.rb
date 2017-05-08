require 'airtable'
require 'airrecord'
require 'meaning'
require 'yaml'

AIRTABLE_API_KEY = YAML.load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'secrets.yml'))["airtable_key"]
VOCABULARY_BASE_KEY = YAML.load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'secrets.yml'))["base_key"]

Airrecord.api_key = AIRTABLE_API_KEY

class Vocabulary < Airrecord::Table
  self.base_key = VOCABULARY_BASE_KEY
  self.table_name = "Words"

  def self.new_words
    all(filter: "{Meaning} = ''")
  end
end

class MeaningService
  attr_accessor :word

  def initialize(word)
    self.word = word
  end

  def find
    entry = Meaning::MeaningLab.new(self.word[:word]).dictionary
  rescue StandardError => e
    puts "Got an error"
  end
end

class FindMeaning
  def self.perform(limit: nil)
    new_words = limit ? Vocabulary.new_words.first(limit) : Vocabulary.new_words

    new_words.each do |word|
      puts "Word: #{word[:word]}"
      dictionary_entry = MeaningService.new(word).find
      if dictionary_entry
        meaning = dictionary_entry[:definitions].join('\n')
        usage = dictionary_entry[:examples].join('\n')
        puts "Meaning: #{meaning}"
        puts "Usage: #{usage}"
      end
      puts ""
    end
  end
end

FindMeaning.perform(limit: 10)
