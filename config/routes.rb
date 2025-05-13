Rails.application.routes.draw do
  # トップページは新規投稿ページ
  root "submissions#new"

  resources :submissions, only: [:new, :create, :show] do
    member do
      get 'image_status'  # 画像生成状態確認用エンドポイント（特定の投稿のIDが必要）
    end
    collection do
      get 'search_books'  # Google Books API検索用エンドポイント（IDは不要）
    end
  end
end
