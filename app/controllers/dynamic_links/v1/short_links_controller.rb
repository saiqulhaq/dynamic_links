class DynamicLinks::V1::ShortLinksController < ApplicationController
  def create
    url = params.require(:url)
    client = DynamicLinks::Client.find_by(api_key: params.require(:api_key))

    unless client
      render json: { error: 'Invalid API key' }, status: :unauthorized
      return
    end

    render json: DynamicLinks.generate_short_url(url, client), status: :created
  rescue DynamicLinks::InvalidURIError
    render json: { error: 'Invalid URL' }, status: :bad_request
  end
end
