Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :cars, only: [] do
    collection do
      post :search
    end
  end
end
