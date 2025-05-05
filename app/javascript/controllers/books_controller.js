import { Controller } from "@hotwired/stimulus";

// 本の検索と選択を管理するコントローラー
export default class extends Controller {
  static targets = [
    "searchInput", // 検索入力フィールド
    "searchResults", // 検索結果表示エリア
    "selectedBooks", // 選択された本のリストコンテナ
    "title", // タイトル表示要素
    "author", // 著者表示要素
    "coverImage", // 書影表示要素
  ];

  connect() {
    // 検索結果の外側をクリックしたら閉じる
    document.addEventListener("click", (e) => {
      const searchContainer = this.searchResultsTarget.parentElement;
      // クリックされた要素が検索コンテナの外側の場合のみ非表示
      if (!searchContainer.contains(e.target)) {
        this.hideResults();
      }
    });

    // 検索結果内のクリックイベントは親要素に伝播させない
    this.searchResultsTarget.addEventListener("click", (e) => {
      e.stopPropagation();
    });
  }

  // 検索結果を表示
  showResults() {
    if (this.searchResultsTarget.innerHTML.trim() !== "") {
      this.searchResultsTarget.classList.remove("hidden");
    }
  }

  // 検索結果を非表示
  hideResults() {
    this.searchResultsTarget.classList.add("hidden");
    // フォーカスが外れた後に内容をクリア
    setTimeout(() => {
      this.searchResultsTarget.innerHTML = "";
    }, 200);
  }

  // 検索入力時の処理
  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      const query = this.searchInputTarget.value.trim();
      if (query.length < 2) {
        this.searchResultsTarget.innerHTML = "";
        this.hideResults();
        return;
      }

      this.fetchBooks(query);
    }, 300);
  }

  // Google Books APIを使用して本を検索
  async fetchBooks(query) {
    try {
      const response = await fetch(
        `/submissions/search_books?query=${encodeURIComponent(query)}`
      );
      const data = await response.json();

      if (data.books.length === 0) {
        this.searchResultsTarget.innerHTML =
          '<div class="p-4 text-gray-500">該当する本が見つかりませんでした</div>';
      } else {
        this.searchResultsTarget.innerHTML = this.renderSearchResults(
          data.books
        );
      }
      this.showResults();
    } catch (error) {
      console.error("Search failed:", error);
      this.searchResultsTarget.innerHTML =
        '<div class="p-4 text-red-500">検索中にエラーが発生しました</div>';
    }
  }

  // 検索結果のHTMLを生成
  renderSearchResults(books) {
    return books
      .map(
        (book) => `
      <div class="p-4 hover:bg-gray-100 cursor-pointer flex items-start gap-4"
           data-action="click->books#selectBook"
           data-book-title="${book.title}"
           data-book-author="${book.author}"
           data-book-cover="${book.cover_url}">
        <div class="w-16 h-24 bg-gray-100 flex items-center justify-center overflow-hidden">
          ${
            book.cover_url
              ? `<img src="${book.cover_url}"
                     class="w-full h-full object-cover"
                     onerror="this.parentElement.innerHTML='<span class=\'text-gray-400 text-sm\'>表紙なし</span>'">`
              : `<span class="text-gray-400 text-sm">表紙なし</span>`
          }
        </div>
        <div class="flex-grow">
          <div class="font-bold mb-1 line-clamp-2">${book.title}</div>
          <div class="text-gray-600 text-sm">${book.author}</div>
        </div>
      </div>
    `
      )
      .join("");
  }

  // 本を選択した時の処理
  selectBook(event) {
    // イベントの伝播を止める
    event.preventDefault();
    event.stopPropagation();

    const activeIndex = this.getActiveBookIndex();
    if (activeIndex === -1) return;

    const bookData = event.currentTarget.dataset;
    const titleElements = this.titleTargets;
    const authorElements = this.authorTargets;
    const coverElements = this.coverImageTargets;

    // フォームを探す（最も近い祖先のform要素）
    const form = event.target.closest("form");
    if (!form) {
      console.error("Form not found");
      return;
    }

    // フォームフィールドとプレビューを更新
    titleElements[activeIndex].textContent = bookData.bookTitle;
    authorElements[activeIndex].textContent = bookData.bookAuthor;

    const coverImage = coverElements[activeIndex];
    const coverContainer = coverImage.parentElement;

    // プレースホルダーと画像の表示を制御
    const placeholder = coverContainer.querySelector("span");
    if (bookData.bookCover) {
      coverImage.src = bookData.bookCover;
      coverImage.classList.remove("hidden");
      if (placeholder) {
        placeholder.classList.add("hidden");
      }
    } else {
      coverImage.classList.add("hidden");
      if (placeholder) {
        placeholder.classList.remove("hidden");
      }
    }

    // hidden フィールドを更新
    const prefix = `submission[submission_books_attributes][${activeIndex}]`;
    form.querySelector(`input[name="${prefix}[title]"]`).value =
      bookData.bookTitle;
    form.querySelector(`input[name="${prefix}[author]"]`).value =
      bookData.bookAuthor;
    form.querySelector(`input[name="${prefix}[cover_url]"]`).value =
      bookData.bookCover;

    // 検索フィールドをクリアして結果を非表示
    this.searchInputTarget.value = "";
    this.searchResultsTarget.innerHTML = "";
    this.hideResults();

    // 少し遅延させてからフォーカスを設定（UIの更新が完了してから）
    setTimeout(() => {
      this.searchInputTarget.focus();
      this.searchInputTarget.select(); // テキストを選択状態に
    }, 100);
  }

  // 現在アクティブな（未選択の）本のインデックスを取得
  getActiveBookIndex() {
    return this.titleTargets.findIndex(
      (el) => el.textContent.trim() === "タイトルを選択してください"
    );
  }
}
