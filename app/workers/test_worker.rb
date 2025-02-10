class TestWorker
  include Sidekiq::Worker

  def execute
    url = 'https://openlibrary.org/api/books?bibkeys=ISBN:0385472579&format=json&jscmd=data'
    response = HTTParty.get(url)
    [response.code, JSON.parse(response.body)]
  end
end
