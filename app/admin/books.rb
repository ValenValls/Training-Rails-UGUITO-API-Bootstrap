ActiveAdmin.register Book do
  filter :title
  filter :author
  filter :year
  filter :publisher
  filter :genre

  permit_params = %i[
    genre author image title publisher year user_id utility_id
  ]

  member_action :copy, method: :get do
    @book = resource.dup
    render :new, layout: false
  end

  controller do
    define_method :permitted_params do
      params.permit(active_admin_namespace.permitted_params, book: permit_params)
    end
  end

  index do
    selectable_column
    id_column
    column :title
    column :author
    actions
  end

  show do |book|
    render 'show', locals: { book: book }
    active_admin_comments
  end

  form do |f|
    f.inputs 'Book Details', allow_destroy: true do
      f.semantic_errors(*f.object.errors.keys)
      f.input :title
      f.input :author
      f.input :year
      f.input :genre
      f.input :publisher
      f.input :image, as: :url
      f.input :user, as: :select, collection: user_collection
      f.input :utility, as: :select, collection: utility_collection
      f.actions
    end
  end
end

def utility_collection
  Utility.all.collect { |utility| [utility.name, utility.id] }
end

def user_collection
  User.all.collect { |user| ["#{user.first_name} #{user.last_name}", user.id] }
end
