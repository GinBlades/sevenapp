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

get "/hello" do
  "Hello, Sinatra"
end

def get_all_bookmarks
  puts("Bookmarks #{Bookmark.all}")
  Bookmark.all(order: :title)
end

# Serve only JSON
# get "/bookmarks" do
#   content_type :json
#   get_all_bookmarks.to_json
# end

get "/bookmarks" do
  @bookmarks = get_all_bookmarks
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
  [201, "/bookmarks/#{bookmark['id']}"]
end

get "/bookmarks/:id" do
  id = params[:id]
  @bookmark = Bookmark.get(id)
  respond_with :bookmark_form_edit, @bookmark
end

put "/bookmarks/:id" do
  id = params[:id]
  bookmark = Bookmark.get(id)
  input = params.slice "url", "title"
  bookmark.update(input)
  204 # No content
end

delete "/bookmarks/:id" do
  id = params[:id]
  bookmark = Bookmark.get(id)
  bookmark.destroy
  200 # OK
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

# Reopen Hash to add slice method
class Hash
  # produce new hash using whitelisted keys
  def slice(*whitelist)
    whitelist.inject({}) { |result, key| result.merge(key => self[key]) }
  end
end
