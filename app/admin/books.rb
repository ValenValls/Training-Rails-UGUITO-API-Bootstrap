ActiveAdmin.register Book do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :utility_id, :user_id, :genre, :author, :image, :title, :publisher, :year
  #
  # or
  #

  belongs_to :user
  belongs_to :utility
  permit_params do
    permitted = %i[genre author image title publisher year]
    permitted << :other if params[:action] == 'create' && current_user.admin?
    permitted
  end
end
