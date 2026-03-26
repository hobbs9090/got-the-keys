GotTheKeys::Application.routes.draw do

  root 'welcome#index'

  devise_for :users, path_names: {sign_up: "register"}

  devise_for :admins, except: [:update, :destroy, :new, :create, :show, :edit]

  namespace :admin do
    root 'dashboard#index'

    resource :dashboard, only: :show, controller: :dashboard
    get :bookings, to: 'appointments#index'
    resource :booking_configuration, only: [:show, :update]
    resource :qa, only: :show, controller: :qa
    resources :appointments, only: [:index, :show, :edit, :update] do
      patch :transition, on: :member
      post :send_reminder, on: :member
    end
    resources :enquiries, only: [:index, :show, :update]
    resources :properties, only: [:index, :show, :edit, :update] do
      patch :transition, on: :member
    end
    resources :users, only: [:index, :show]
    resources :notification_logs, only: :index
    resources :demo_scenarios, only: [:index, :show], path: 'demo-data' do
      post :apply, on: :member
      collection do
        post :restore_baseline
        get :import
        post :preview_import
        post :apply_import
        get :export
      end
    end
  end

  resources :members, only: [:index]

  resources :statistics, only: [:index]

  resources :coffee, only: [:index]

  resources :properties do
    resources :photos, only: [:index, :new, :create, :update, :destroy]
    resources :floor_plans, only: [:index, :new, :create, :update, :destroy]
    resources :viewing_times, only: [:index, :new, :create]
    resources :enquiries, only: [:new, :create]
    resources :appointments, only: [:new, :create]
  end

  resources :appointments, only: [:show], param: :public_reference do
    member do
      get :edit_self_service, path: "manage"
      patch :reschedule_self_service, path: "reschedule"
      patch :cancel_self_service, path: "cancel"
    end
  end

  resources :for_sale, only: [:index]

  resources :for_rent, only: [:index]

  resources :language, only: [:new]

  resources :searches, only: [:index]

  resources :location, only: [:show]

  resources :users, only: [:show]

  resources :legal, only: [:index]

  resources :cookie_policy, only: [:index]
  resource :cookie_preferences, only: [:update]

  resources :how_it_works, only: [:index]

  resources :about_us, only: [:index]

  resources :contact_us, only: [:index]

  resources :blog, only: [:index]
  get '/baits', to: redirect('/blog', status: 302)

end
