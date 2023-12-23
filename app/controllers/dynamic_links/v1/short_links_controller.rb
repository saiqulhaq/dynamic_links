class DynamicLinks::V1::ShortLinksController < ApplicationController
  def create
    render json: {
      shortLink: 'http://link',
      previewLink: 'http://xxx.goo.gl/foo?preview',
      warning: [{
        'warningCode' => 'UNRECOGNIZED_PARAM',
        'warningMessage' => '...'
      }]
    }
  end
end
