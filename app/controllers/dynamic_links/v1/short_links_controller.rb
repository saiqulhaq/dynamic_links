class DynamicLinks::V1::ShortLinksController < ApplicationController
    short_url = DynamicLinks.shorten(url)
    render json: {
      shortLink: short_link.short_url,
      previewLink: "#{short_link.short_url}?preview=true",
      warning: []
    }, status: :created
  end
end
