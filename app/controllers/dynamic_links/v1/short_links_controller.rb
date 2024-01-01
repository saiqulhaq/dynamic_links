class DynamicLinks::V1::ShortLinksController < ApplicationController
  def create
    url = params.require(:url)
    # validate url
    # if !url_shortener.valid_url?(url)
    #   render json: { error: 'invalid url' }, status: :bad_request
    #   return
    # end

    # shorten url
    # save to db (not implemented yet)
    render json: DynamicLinks.generate_short_url(url), status: :created
  end
end
