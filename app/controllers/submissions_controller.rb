class SubmissionsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  def new
    @submission = Submission.new
    3.times { @submission.submission_books.build }
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
    # Google Books APIの実装は後ほど追加
    render json: { books: [] }
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
