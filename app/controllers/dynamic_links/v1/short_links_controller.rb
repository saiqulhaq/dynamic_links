class DynamicLinks::V1::ShortLinksController < ApplicationController
  def create
    # expected response json format
    # {
    #   shortLink: 'http://link',
    #   previewLink: 'http://xxx.goo.gl/foo?preview',
    #   warning: [{
    #     'warningCode' => 'UNRECOGNIZED_PARAM',
    #     'warningMessage' => '...'
    #   }]
    # }
    url = params.require(:url)
    # validate url
    if !url_shortener.valid_url?(url)
      render json: { error: 'invalid url' }, status: :bad_request
      return
    end
    # shorten url
    short_url = url_shortener.shorten(url)
    # save to db (not implemented yet)
    # short_link = ShortLink.create!(url: url, short_url: short_url)
    # render json
    render json: {
      shortLink: short_link.short_url,
      previewLink: "#{short_link.short_url}?preview}",
      warning: []
    }, status: :created
  end
end
