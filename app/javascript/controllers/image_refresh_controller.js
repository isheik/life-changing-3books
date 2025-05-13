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
    // ページ全体をリフレッシュ
    Turbo.visit(window.location.href, { action: "replace" });
  }
}
