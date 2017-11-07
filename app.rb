class App < Sinatra::Base
  helpers do
    def stream_url
      scheme = request.secure? ? "https" : "http"
      host   = request.host
      port   = request.port == 80 ? "" : ":#{request.port}"
      "%s://%s%s%s" % [scheme, host, port, "/stream"]
    end
  end

  get "/" do
    erb :index
  end

  post "/messages" do
    data = { body: params[:body] }
    kafka.deliver_message(data.to_json, topic: "test")
    "ok"
  end

  use Rack::Cors do
    allow do
      origins "*"
      resource "/stream",
        headers: :any,
        methods: [:get],
        expose:  ["Transfer-Encoding"]
    end
  end

  get "/stream" do
    stream do |out|
      kafka.each_message(topic: "test") do |message|
        out << message.value + "\n\n"
      end
    end
  end

  private

  def kafka
    @kafka ||= Kafka.new(
      seed_brokers: ["localhost:9092"],
      client_id: "ridge",
    )
  end
end
