import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 }, // 5秒ごとに更新
  };

  connect() {
    if (!this.element.querySelector("img")) {
      this.startRefreshing();
    }
  }

  disconnect() {
    this.stopRefreshing();
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh();
    }, this.intervalValue);
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
  }

  refresh() {
    // 画像状態のみを更新（Turbo Frameを使用）
    const submissionId = window.location.pathname.split("/").pop();
    // GETリクエストを送信すると、Turbo Frameが自動的に更新される
    fetch(`/submissions/${submissionId}/image_status`).then((response) => {
      if (response.ok) {
        response.text().then((html) => {
          // 画像が生成されていた場合は自動更新を停止
          if (html.includes("image_tag")) {
            this.stopRefreshing();
          }
        });
      }
    });
  }
}
