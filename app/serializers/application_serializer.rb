class ApplicationSerializer < ActiveModel::Serializer
  def render?(attribute_name)
    if defined? options
      options.include?(attribute_name)
    else
      false
    end
  end
end
