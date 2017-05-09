require 'airtable'
require 'airrecord'
require 'meaning'
require 'yaml'
require 'byebug'

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
    puts "Got an error: #{e.message}"
  end
end

class FindMeaning
  def self.perform(limit: nil)
    new_words = limit ? Vocabulary.new_words.first(limit) : Vocabulary.new_words

    new_words.each_with_index do |word, index|
      puts "#{index + 1} Word: #{word[:word]}"
      dictionary_entry = MeaningService.new(word).find
      if dictionary_entry
        meaning = dictionary_entry[:definitions].join(' OR ') if dictionary_entry[:definitions]
        usage = dictionary_entry[:examples].join(' OR ') if dictionary_entry[:examples]
        puts "Meaning: #{meaning}"
        puts "Usage: #{usage}"
        word[:Meaning] = meaning if meaning
        word[:Usage] = usage if usage
        word.save
      end
      puts ""
    end
  end
end

FindMeaning.perform
