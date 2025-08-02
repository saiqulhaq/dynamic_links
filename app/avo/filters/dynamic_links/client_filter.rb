class Avo::Filters::DynamicLinks::ClientFilter < Avo::Filters::SelectFilter
  self.name = "Client"

  def apply(request, query, values)
    return query if values.blank?

    query.where(client_id: values)
  end

  def options
    DynamicLinks::Client.all.pluck(:name, :id).to_h
  end
end
