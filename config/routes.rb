Rails.application.routes.draw do
  # トップページは新規投稿ページ
  root "submissions#new"

  resources :submissions, only: [:new, :create, :show] do
    collection do
      get 'search_books'  # Google Books API検索用エンドポイント
    end
  end
end
