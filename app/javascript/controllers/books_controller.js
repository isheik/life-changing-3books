import { Controller } from "@hotwired/stimulus";
import { useMutation } from "stimulus-use";

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
      if (!this.element.contains(e.target)) {
        this.hideResults();
      }
    });

    this.element.addEventListener("click", (e) => {
      const target = e.target.closest(
        "[data-action='click->books#selectBook']"
      );
      if (target) this.selectBook({ currentTarget: target });
    });

    // useMutation(this, {
    //   element: this.searchResultsTarget, // ✅ 監視対象を指定
    //   childList: true, // ✅ 子要素の変化を監視
    // });
  }

  // 検索結果を表示
  showResults() {
    this.searchResultsTarget.classList.remove("hidden");
  }

  // 検索結果を非表示
  hideResults() {
    this.searchResultsTarget.classList.add("hidden");
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
    console.log("aaaaa");

    const activeIndex = this.getActiveBookIndex();
    console.log("Active index:", activeIndex);
    console.log(
      "Current title targets:",
      this.titleTargets.map((el) => el.textContent)
    );

    if (activeIndex === -1) {
      console.log("No empty slot available");
      return;
    }

    console.log("Selected book data:", event.currentTarget.dataset);

    const bookData = event.currentTarget.dataset;
    const titleElements = this.titleTargets;
    const authorElements = this.authorTargets;
    const coverElements = this.coverImageTargets;
    const form = this.element.querySelector("form");

    // フォームフィールドとプレビューを更新
    titleElements[activeIndex].textContent = bookData.bookTitle;
    authorElements[activeIndex].textContent = bookData.bookAuthor || "著者不明";

    const coverImage = coverElements[activeIndex];
    const coverContainer = coverImage.parentElement;
    const placeholderText = coverContainer.querySelector("span");

    if (bookData.bookCover) {
      coverImage.src = bookData.bookCover;
      coverImage.classList.remove("hidden");
      placeholderText?.classList.add("hidden");

      // エラー時の処理を追加
      coverImage.onerror = () => {
        coverImage.classList.add("hidden");
        placeholderText?.classList.remove("hidden");
      };
    }

    // hidden フィールドを更新
    const prefix = `submission[submission_books_attributes][${activeIndex}]`;

    // フォームフィールドの取得
    const titleField = form.querySelector(`input[name="${prefix}[title]"]`);
    const authorField = form.querySelector(`input[name="${prefix}[author]"]`);
    const coverUrlField = form.querySelector(
      `input[name="${prefix}[cover_url]"]`
    );
    const bookOrderField = form.querySelector(
      `input[name="${prefix}[book_order]"]`
    );

    console.log("Form fields found:", {
      title: titleField !== null,
      author: authorField !== null,
      coverUrl: coverUrlField !== null,
      bookOrder: bookOrderField !== null,
    });

    // フィールドの値を設定
    titleField.value = bookData.bookTitle;
    authorField.value = bookData.bookAuthor || "著者不明";
    coverUrlField.value = bookData.bookCover || "";

    console.log("Updated form values:", {
      title: titleField.value,
      author: authorField.value,
      coverUrl: coverUrlField.value,
      bookOrder: bookOrderField.value,
    });

    // 検索フィールドをクリアし、結果を非表示
    this.searchInputTarget.value = "";
    this.searchResultsTarget.innerHTML = "";
    this.hideResults();
    this.searchInputTarget.blur();
  }

  // 現在アクティブな（未選択の）本のインデックスを取得
  getActiveBookIndex() {
    const selectedCount = this.titleTargets.reduce((count, el) => {
      return (
        count + (el.textContent.trim() === "タイトルを選択してください" ? 0 : 1)
      );
    }, 0);

    // 1番目から順に埋めていく
    return this.titleTargets.findIndex(
      (el) => el.textContent.trim() === "タイトルを選択してください"
    );
  }
}
