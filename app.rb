require "sinatra"
require "sinatra/respond_with" # from sinatra-contrib
require "data_mapper"
require "dm-serializer"
require "slim"
require_relative "models/bookmark"

# Explicitly set so that 'respond_with' will not look for haml
set :template_engines, {
  css: [],
  xml: [],
  js: [],
  html: [:slim],
  all: [:slim],
  json: []
}

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/bookmarks.db")
DataMapper.finalize.auto_upgrade! # Create or update tables as needed

# Works with all actions using '/bookmarks/:id' (get, put, delete)
before "/bookmarks/:id" do |id|
  @bookmark = Bookmark.get(id)
  if !@bookmark
    halt 404, "Bookmark #{id} not found"
  end
end

get "/hello" do
  "Hello, Sinatra"
end

def get_all_bookmarks
  Bookmark.all(order: :title)
end

# Serve only JSON
# get "/bookmarks" do
#   content_type :json
#   get_all_bookmarks.to_json
# end

get "/bookmarks/*" do
  tags = params[:splat].first.split("/")
  @bookmarks = get_all_bookmarks
  tags.each do |tag|
    @bookmarks = bookmarks.all({ taggings: { tag: { label: tag }}}) 
  end
  respond_with :bookmark_list, @bookmarks
end

get "/bookmarks/new" do
  slim :bookmark_form_new
end

post "/bookmarks" do
  input = params.slice "url", "title"
  bookmark = Bookmark.create(input)
  # Given an array, Sinatra will set [status_code, body]
  # With three elements, it will be [status code, header hash, body]
  if bookmark.save
    add_tags(bookmark)
    # Created
    [201, "/bookmarks/#{bookmark['id']}"]
  else
    400 # Bad Request
  end
end

# Using block parameters
get "/bookmarks/:id" do
  respond_with :bookmark_form_edit, @bookmark
end

put "/bookmarks/:id" do
  input = params.slice("url", "title").reject { |k, v| v.nil? }
  if @bookmark.update(input)
    204 # No content
  else
    400 # Bad Request
  end
end

delete "/bookmarks/:id" do
  @bookmark.destroy
  200 # OK
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def add_tags(bookmark)
    labels = (params["tagsAsString"] || "").split(",").map(&:strip)
    existing_labels = []
    bookmark.taggings.each do |tagging|
      if labels.include? tagging.tag.label
        existing_labels.push(tagging.tag.label)
      else
        tagging.destroy
      end
    end
    (labels - existing_labels).each do |label|
      tag = { label: label }
      existing = Tag.first(tag)
      if !existing
        existing = Tag.create(tag)
      end
      Tagging.create(tag: existing, bookmark: bookmark)
    end
  end
end

# Reopen Hash to add slice method
class Hash
  # produce new hash using whitelisted keys
  def slice(*whitelist)
    whitelist.inject({}) { |result, key| result.merge(key => self[key]) }
  end
end
