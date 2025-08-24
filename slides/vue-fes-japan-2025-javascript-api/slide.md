---
marp: true
theme: gaia
paginate: true
header: "**フロントエンドカンファレンス東京 x Vue Fes Japan** JavaScriptのAPIはどこから来る？"
footer: "by **ユウト**"
---

# JavaScriptのAPIはどこから来る？
## 〜普段使っているAPIが現場に届くまで〜

**yossydev**
フロントエンドカンファレンス東京 x Vue Fes Japan

---

## 今日話すこと

フレームワークではなく、皆さんが**当たり前のように使っているAPI**たちがどのように生み出されているのか

OSS活動を軸に話していきます

---

## 問題提起

フロントエンドの移り変わりが早すぎて疲れませんか？

新しいフレームワークが月1で出る現状...

---

## でもよく考えてみてください

どんなフレームワークを使っても、結局は`Array.map()`や`fetch()`を使っていますよね？

---

## 根本を知る重要性

「また新しいの？」
↓
**「ああ、これはあれのラッパーね」**

技術選定の軸を作りましょう

---

## APIの分類

よく使われる3つのAPIを例に：

- `Array.prototype.map`
- `console.log`
- `fetch`

実はこれらには**出生地の違い**があります

---

## 3つの種類

そしてこれらのAPIには、以下のような違いがあります。

- **Array.prototype.map**: JavaScript Engine（ECMA-262）
- **console.log**: Runtime（WHATWG/WinterTC）
- **fetch**: Runtime（WHATWG/WinterTC）

---

# Engine系APIの実装現場

---

## Array.prototype.map の場合

- **JavaScript Engine**が持っているAPI
- 仕様書：**TC39のECMA-262**
- 有名なEngine：
  - Google V8
  - Apple JavaScriptCore
  - Mozilla SpiderMonkey

---

## 私の取り組み：Nova

- **Nova** JavaScript Engineにコントリビュート
- 「なんで作るのか？」→「**作りたいから**」
- Test262通過率：**75%**
- 主要Engine：90%超え

---

## Test262とは

ECMA-262の仕様書通りにAPIが作られているかをチェック

最近RegExpに取り組み中
来月には**80%**到達予定

---

# Runtime系APIの実装現場

---

## Runtime経由での実行

ただ、皆さんは普段どのランタイムがどのEngineを使っているかなんて意識しないですよね。ましてやEngineをcloneして手元でAPIを実行するみたいなこともしないですよね。

おそらく9割くらいの人は、EngineのAPIを**Runtime経由**で実行していると思います。

---

## JavaScript Runtimeといえば？

**ブラウザ**：
- Chrome（V8）
- Safari（JavaScriptCore）

**サーバーサイド**：
- Node.js（V8）
- Deno（V8 + Rust）
- Bun（JavaScriptCore + Zig）

---

## 私の取り組み：Andromeda

- **Andromeda** JavaScript Runtime開発メンバー
- NovaをベースとしたサーバーサイドRuntime
- WinterTC Invited Expert
- 目標：**minimal common API**の実装

---

## fetchの実装

fetchの仕様って膨大で、自分が思っていた以上に大きいものになっています。

Request/Response/Headerクラスとかもfetchの範囲になってくるし、さらにfetch methodからfetching/main fetch/schema fetch/http fetch/http network fetchみたいに分類されていたりします。仕様書1000ページ超えです。

---

## コントリビュートのすすめ

**サーバーサイドRuntimeがおすすめ**：

- Engineの実装は複雑（前提知識が必要）
- Runtime（特にNode）は仕様書通りの実装
- fetchにはTODOも残っている

---

# エコシステム戦略

---

## まとめ

3つのAPIの出生地：
- **JavaScript Engine/Runtime**によって作られる
- Engine仕様：**ECMA-262**
- Runtime仕様：**WHATWG/WinterTC**

---

## 普及への課題

特定課題解決ライブラリ → 必然的にユーザー増加

しかし**Runtimeは特殊**：
- Bunのような圧倒的な速さが必要
- Andromedaは理論上早いが検証段階

---

## エコシステム戦略

**既存エコシステムに乗っかる**のが最速

日本で最もホットなJSソフトウェアは？

**Hono**のAdaptorとして提供が目標

---

## 興味を持ったのであれば

engineでもruntimeでもいいので、コードと仕様書を見比べてみましょう。

おすすめはコードを少しいじって、テスト走らせてみていくと実際に今日のチェックもできるので理解が進むと思います。

---

## クロージング

EngineとRuntimeの挙動を知ると：
- 知らないJavaScriptの挙動を発見
- **めっちゃ楽しい！**

ぜひ皆さんも興味があれば触ってみてください！

---

## Thank you!

質問があれば気軽にどうぞ 🙋‍♂️

**yossydev**

---

<small>※このスライドはスピーカーノートを元にAIに作成してもらいました</small>