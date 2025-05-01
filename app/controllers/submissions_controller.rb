class SubmissionsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  def new
    @submission = Submission.new
    3.times do |i|
      @submission.submission_books.build(book_order: i + 1)
    end
  end

  def create
    @submission = Submission.new(submission_params)
    
    if @submission.save
      redirect_to submission_path(@submission), notice: '投稿が完了しました'
    else
      # バリデーションエラー時は入力フォームを再表示
      flash.now[:alert] = '投稿に失敗しました。入力内容を確認してください。'
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @submission = Submission.find_by!(uuid: params[:id])
  end

  def search_books
    query = params[:query]
    return render json: { books: [] } if query.blank?

    begin
      # Google Books APIで検索を実行
      books = GoogleBooks.search(query, { country: 'JP', count: 5 })
      
      # 必要な情報を抽出
      results = books.map do |book|
        # GoogleBooks::Itemインスタンスから直接データを取得
        info = book.instance_variable_get(:@volume_info)
        
        {
          title: book.title,
          author: book.authors || '著者不明',
          cover_url: begin
            links = info['imageLinks'] || {}
            url = links['thumbnail'] || links['smallThumbnail']
            url ? url.gsub('http://', 'https://') : ''
          rescue => e
            Rails.logger.error "Image URL extraction error: #{e.message}"
            ''
          end,
          description: book.description
        }
      end

      render json: { books: results }
    rescue => e
      Rails.logger.error "Google Books API error: #{e.message}"
      render json: { error: '検索中にエラーが発生しました', books: [] }, status: :service_unavailable
    end
  end

  private

  def submission_params
    params.require(:submission).permit(
      :comment,
      submission_books_attributes: [:title, :author, :cover_url, :book_order]
    )
  end

  def render_404
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end
end
