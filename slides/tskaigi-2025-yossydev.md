---
title: "Rust製JavaScript EngineのTypeScriptサポート"
description: "近年、TypeScriptは広く普及し、主要なJavaScriptランタイムも対応を進めています。しかし、これらはあくまでランタイム側でのサポートであり、エンジン自体がTypeScriptを直接実行するわけではありません。本LTでは、Rust製JavaScriptエンジン Nova におけるTypeScript実行の取り組みを紹介し、エンジンレベルでのTypeScriptサポートの可能性について考察します。"
marp: true
theme: default
paginate: true
---

# Rust製JavaScript EngineのTypeScriptサポート

2025/05/23 [tskaigi 2025](https://2025.tskaigi.org/talks/yossydev)

---

## Rust製JavaScript Engine is Nova

- [Why build a JavaScript engine?](https://trynova.dev/blog/why-build-a-js-engine)
- [What is the Nova JavaScript engine?](https://trynova.dev/blog/what-is-the-nova-javascript-engine)
- Rust言語で書かれたJavaScriptエンジン
- test262の通過率は約66%
    1. 大体動く: Array,Map,TypedArray,Proxy, etc…
    2. 未実装: Module,RegExp,Atomic, etc…

---

## JavaScript EngineでTypeScriptを実行する（🤔）

---

## JavaScript EngineでTypeScriptを実行する（🤔）
Q. 以下のコードをブラウザで動かしてください。
```ts
const str: string = "TSKaigi 2025!!"
```

---

## JavaScript EngineでTypeScriptを実行する（🤔）
Q. 以下のコードをブラウザで実行してください。

```ts
const str: string = "TSKaigi 2025!!"
```

A. 型アノテーションはJavaScriptの構文ではないので構文エラーとなる。
（`Uncaught SyntaxError: Missing initializer in const declaration`）

---

## Novaでは
Novaでは、Rustのfeatureフラグを使用することでTypeScriptを実行できるようになっている

```ts
const str: string = "TSKaigi 2025!!"

$ cargo run --features typescript eval index.ts
$ andromeda run index.ts
```

---

## Novaでは

```rs
let mut source_type = if strict_mode {
    SourceType::default().with_module(true)
} else {
    SourceType::default().with_script(true)
};
if cfg!(feature = "typescript") {
    source_type = source_type.with_typescript(true);
}
```

もしかしたらjsxも動くかも...？？👀

```ts
if cfg!(feature = "jsx") {
    source_type = source_type.with_jsx(true);
}
```

---

## どのようにサポートしているのか？

- Parserにoxcを使用
- Parse後にJavaScriptエンジンなら当然、bytecodeにコンパイルする処理を書く必要がある
- TypeScript独自の構文であるenumやnamespaceも同様にJavaScript Engineが扱うならbytecodeにコンパイルさせる必要がある
- enumはtskaigiまでに間に合わせようと思っていたけどサボった
（ https://github.com/trynova/nova/pull/598 ）

---

## 正式にサポートするの？

- わからない
- TypeScriptのサポートをメインに考えているわけではないので、ネイティブサポートするかはわからない
  - まずtest262を通すことが優先。
- strip-typesのサポートも聞いたら、「やってみたら動いた！」みたいな感じだった。
- なので誰か手が空いた人が進めていくみたいな感じにはなると思う。

---

## 個人的な意見

現状の開発において、TypeScriptを使わないことはありえなくなってきている（というかなっている）。
であれば、JS EngineがTypeScriptをネイティブで実行できるようにしても良いのかなと思う。
そしてその結果、あわよくば型情報を使った最適化を可能にし、よりJavaScriptが高速で動くことを期待したい。
