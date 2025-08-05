class Avo::Filters::DynamicLinks::SchemeFilter < Avo::Filters::SelectFilter
  self.name = "Scheme"

  def apply(request, query, values)
    return query if values.blank?

    query.where(scheme: values)
  end

  def options
    {
      "HTTPS" => "https",
      "HTTP" => "http"
    }
  end
end
