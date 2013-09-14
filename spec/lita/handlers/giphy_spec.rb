require 'spec_helper'

describe Lita::Handlers::Giphy, lita_handler: true do
  it { routes_command("giphy swanson dance").to :giphy }
  it { routes_command("gif swanson dance").to :giphy }
  it { routes_command("animate swanson dance").to :giphy }

  it "sets the Giphy API key to nil by default" do
    expect(Lita.config.handlers.giphy.api_key).to be_nil
  end

  describe "#giphy" do
    it "replies that the Giphy API key is required" do
      send_command("giphy swanson dance")
      expect(replies.last).to include("Giphy API key required")
    end

    context "when the Giphy API key is set" do
      before do
        Lita.config.handlers.giphy.api_key = "foobarbaz"
      end

      context "with a result-returning query" do
        let(:body) do
          <<-BODY.chomp
  { "data":[
    {"type":"gif", "id":"11nMit55uRGIuc", "url":"http:\/\/giphy.com\/gifs\/11nMit55uRGIuc",
    "bitly_gif_url":"http:\/\/gph.is\/18Abg9K", "bitly_fullscreen_url":"http:\/\/gph.is\/18AbeyG", "bitly_tiled_url":"http:\/\/gph.is\/17vT1VT", "embed_url":"http:\/\/giphy.com\/embed\/11nMit55uRGIuc", "images":
      {
        "fixed_height":
          {"url":"http:\/\/media0.giphy.com\/media\/11nMit55uRGIuc\/200.gif", "width":"355", "height":"200"}, 
        "fixed_height_still":
          {"url":"http:\/\/media1.giphy.com\/media\/11nMit55uRGIuc\/200_s.gif","width":"355","height":"200"}, 
        "fixed_height_downsampled":
          {"url":"http:\/\/media0.giphy.com\/media\/11nMit55uRGIuc\/200_d.gif","width":"355","height":"200"},
        "fixed_width":
          {"url":"http:\/\/media1.giphy.com\/media\/11nMit55uRGIuc\/200w.gif","width":"200","height":"113"},
        "fixed_width_still":
          {"url":"http:\/\/media2.giphy.com\/media\/11nMit55uRGIuc\/200w_s.gif","width":"200","height":"113"},
        "fixed_width_downsampled":
          {"url":"http:\/\/media0.giphy.com\/media\/11nMit55uRGIuc\/200w_d.gif","width":"200","height":"113"},
        "original": 
          {"url":"http:\/\/media3.giphy.com\/media\/11nMit55uRGIuc\/giphy.gif", "width":"500", "height":"282", "size":"507637","frames":"20"}
      }
    }
  ],
  "pagination":
    {"total_count":5, "count":5, "offset":0},
  "meta":
    {"status":200,"msg":"OK"}
  }
          BODY
        end
        
        let(:response) { double("Faraday::Response", status: 200, body: body) }

        before do
          allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        end

        it "replies with the original URL to a gif" do
          send_command("giphy swanson dance")
          expect(replies.last).to include("http:\/\/media3.giphy.com\/media\/11nMit55uRGIuc\/giphy.gif")
        end
      end

      context "with a query that returns no results" do
        let(:body) { '{"data":[],"pagination":{"total_count":0,"count":0,"offset":0},"meta":{"status":200,"msg":"OK"}}' }
        let(:response) { double("Faraday::Response", status: 200, body: body) }

        before do
          allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        end

        it "responds with an informative message" do
          send_command("giphy asdf")
          expect(replies.last).to include("I couldn't find anything for 'asdf'!")
        end
      end
    end
  end
end
