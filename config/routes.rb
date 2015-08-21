Foundation::Application.routes.draw do

  root 'welcome#index'

  devise_for :users, path_names: {sign_up: "register"}

  devise_for :admins, except: [:update, :destroy, :new, :create, :show, :edit]

  resources :members, only: [:index]

  resources :statistics, only: [:index]

  resources :coffee, only: [:index]

  resources :account_billing, only: [:index]

  resources :properties, only: [:index]

  resources :for_sale, only: [:index]

  resources :for_rent, only: [:index]

  resources :language, only: [:new]

  resources :searches, only: [:index]

  resources :location, only: [:show]

  resources :users do
    resources :properties
  end

  resources :users do
    resources :appointments
  end

  resources :properties do
    resources :photos
  end

  resources :properties do
    resources :floor_plans
  end

  resources :properties do
    resources :viewing_times
  end

  resources :properties do
    resources :appointments
  end

  resources :properties do
    resources :make_an_offer
  end

  resources :legal, only: [:index]

  resources :cookie_policy, only: [:index]

  resources :how_it_works, only: [:index]

  resources :about_us, only: [:index]

  resources :contact_us, only: [:index]

  resources :blog, only: [:index]

end
