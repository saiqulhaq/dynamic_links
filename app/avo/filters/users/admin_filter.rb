class Avo::Filters::Users::AdminFilter < Avo::Filters::BooleanFilter
  self.name = "Admin Status"

  def apply(request, query, values)
    return query if values[:admin].blank? && values[:regular].blank?

    if values[:admin] && values[:regular]
      query # Show all if both are selected
    elsif values[:admin]
      query.where(admin: true)
    elsif values[:regular]
      query.where(admin: false)
    else
      query
    end
  end

  def options
    {
      admin: "Admin users only",
      regular: "Regular users only"
    }
  end
end