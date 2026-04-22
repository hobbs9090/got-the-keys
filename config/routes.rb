GotTheKeys::Application.routes.draw do
  get "/up", to: proc { [200, { "Content-Type" => "text/plain; charset=utf-8" }, ["OK"]] }
  get "/robots.txt", to: "robots#show"

  root 'welcome#index'

  devise_for :users, path_names: {sign_up: "register"}, controllers: { passwords: "users/passwords" }

  devise_for :admins, except: [:update, :destroy, :new, :create, :show, :edit], controllers: { sessions: "admin/sessions" }

  namespace :admin do
    root 'dashboard#index'

    resource :dashboard, only: :show, controller: :dashboard
    get :bookings, to: 'appointments#index'
    resource :booking_configuration, only: [:show, :update]
    resource :qa, only: :show, controller: :qa
    resource :security, only: [:show, :update], controller: :security do
      post :enroll
      patch :confirm
      post :regenerate_backup_codes
      delete :disable
    end
    resources :appointments, only: [:index, :show, :edit, :update] do
      patch :transition, on: :member
      post :send_reminder, on: :member
    end
    resources :sales, only: [:index, :show, :update], controller: :offers
    resources :rentals, only: [:index, :show, :update], controller: :rental_applications
    resources :enquiries, only: [:index, :show, :update]
    resources :properties, only: [:index, :show, :edit, :update] do
      patch :transition, on: :member
    end
    resources :customers, only: [:index, :show], constraints: { id: /[^\/]+/ }, format: false
    resources :sellers, only: [:index, :show], controller: :users
    resources :notification_logs, only: :index
    resources :demo_scenarios, only: [:index, :show], path: 'demo-data' do
      post :apply, on: :member
      collection do
        post :restore_baseline
        post :populate_performance
        get :import
        post :preview_import
        post :apply_import
        get :export
      end
    end

    get "offers", to: redirect("/admin/sales")
    get "offers/:id", to: redirect { |params, _req| "/admin/sales/#{params[:id]}" }
    patch "offers/:id", to: redirect("/admin/sales/%{id}")
    put "offers/:id", to: redirect("/admin/sales/%{id}")

    get "rental_applications", to: redirect("/admin/rentals")
    get "rental_applications/:id", to: redirect { |params, _req| "/admin/rentals/#{params[:id]}" }
    patch "rental_applications/:id", to: redirect("/admin/rentals/%{id}")
    put "rental_applications/:id", to: redirect("/admin/rentals/%{id}")
  end

  resources :members, only: [:index]

  resources :properties do
    collection do
      get :mine
    end

    resource :saved_property, only: [:create, :destroy]
    resources :photos, only: [:index, :create, :update, :destroy]
    resources :floor_plans, only: [:index, :create, :update, :destroy]
    resources :property_documents, path: "documents", only: [:index, :new, :create, :update, :destroy] do
      get :download, on: :member
    end
    resources :viewing_times, only: [:index, :new, :create]
    resources :enquiries, only: [:new, :create]
    resources :offers, only: [:new, :create] do
      patch :withdraw, on: :member
    end
    resources :rental_applications, only: [:new, :create] do
      patch :withdraw, on: :member
    end
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
  resources :saved_searches, only: %i[create destroy]

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
