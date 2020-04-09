# keep this logic in-sync with the frontend (Jekyll's slugify filter)
# https://github.com/jekyll/jekyll/blob/035ea729ff5668dfc96e7f56a86d214e5a633291/lib/jekyll/utils.rb#L204
# We add transliteration to convert non-latin characters to ascii, especially
# for candidate names. e.g. Guillén -> guillen.
def slugify(word)
  I18n.transliterate(word || '')
    .downcase.gsub(/[^a-z0-9-]+/, '-')
end
