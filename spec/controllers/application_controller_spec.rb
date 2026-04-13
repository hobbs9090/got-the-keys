require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller(ApplicationController) do
    def index
      raise ActionController::InvalidAuthenticityToken, "invalid token"
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  it "logs csrf debugging details before re-raising invalid authenticity token errors" do
    exception = nil

    allow(Rails.logger).to receive(:error) do |message|
      expect(message).to include("[csrf-debug] InvalidAuthenticityToken")
      expect(message).to include("method=GET")
      expect(message).to include("path=/index")
    end

    expect { get :index }.to raise_error(ActionController::InvalidAuthenticityToken) { |error| exception = error }
    expect(exception.message).to eq("invalid token")
    expect(Rails.logger).to have_received(:error)
  end
end
