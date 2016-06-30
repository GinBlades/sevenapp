require_relative "../app"
require "json"
require "rspec"
require "rack/test"

describe "Hello application" do
  include Rack::Test::Methods

  let (:json_request) { { "HTTP_ACCEPT" => "application/json" } }

  def app
    Sinatra::Application
  end

  it "says hello" do
    get "/hello"
    expect(last_response).to be_ok
    expect(last_response.body).to eq("Hello, Sinatra")
  end

  it "creates a new bookmark" do
    get "/bookmarks", {}, json_request 
    bookmarks = JSON.parse(last_response.body)
    last_size = bookmarks.size

    post "/bookmarks", { url: "http://www.example.com", title: "Test" }, json_request

    expect(last_response.status).to eq(201)
    expect(last_response.body).to match(/\/bookmarks\/\d+/)

    get "/bookmarks", {}, json_request
    bookmarks = JSON.parse(last_response.body)
    expect(bookmarks.size).to eq(last_size + 1)
  end

  it "updates a bookmark" do
    post "/bookmarks", { url: "http://www.example.com", title: "Test" }, json_request
    bookmark_uri = last_response.body
    id = bookmark_uri.split("/").last

    put "/bookmarks/#{id}", { title: "Success" }, json_request
    expect(last_response.status).to eq(204)

    get "/bookmarks/#{id}", {}, json_request
    retrieved_bookmark = JSON.parse(last_response.body)
    expect(retrieved_bookmark["title"]).to eq("Success")
  end

  it "sends an error code for an invalid create request" do
    post "/bookmarks", { url: "test", title: "Test" }, json_request
    expect(last_response.status).to eq(400)
  end

  it "sends an error code for an invalid update request" do
    get "/bookmarks", {}, json_request
    bookmarks = JSON.parse(last_response.body)
    id = bookmarks.first['id']

    put "/bookmarks/#{id}", { url: "Invalid" }, json_request
    expect(last_response.status).to eq(400)
  end
end
