class Avo::Filters::DynamicLinks::ExpiredFilter < Avo::Filters::BooleanFilter
  self.name = "Expired"

  def apply(request, query, values)
    return query if values[:expired].blank?

    if values[:expired]
      query.where("expires_at < ?", Time.current)
    else
      query.where("expires_at IS NULL OR expires_at >= ?", Time.current)
    end
  end

  def options
    {
      expired: "Show expired only"
    }
  end
end
