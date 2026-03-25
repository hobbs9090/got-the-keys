Foundation::Application.routes.draw do

  root 'welcome#index'

  devise_for :users, path_names: {sign_up: "register"}

  devise_for :admins, except: [:update, :destroy, :new, :create, :show, :edit]

  resources :members, only: [:index]

  resources :statistics, only: [:index]

  resources :coffee, only: [:index]

  resources :account_billing, only: [:index]

  resources :properties do
    resources :photos, only: [:index, :new]
    resources :floor_plans, only: [:index, :new]
    resources :viewing_times, only: [:index, :new, :create]
  end

  resources :for_sale, only: [:index]

  resources :for_rent, only: [:index]

  resources :language, only: [:new]

  resources :searches, only: [:index]

  resources :location, only: [:show]

  resources :users, only: [:show]

  resources :legal, only: [:index]

  resources :cookie_policy, only: [:index]

  resources :how_it_works, only: [:index]

  resources :about_us, only: [:index]

  resources :contact_us, only: [:index]

  resources :blog, only: [:index]

end
