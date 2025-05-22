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
  - 他のJavaScriptエンジン: v8,JavaScriptCore,SpiderMonkey,LibJS,Boaなど
- test262の通過率は約66%
    1. 大体動く: Array,Map,TypedArray,Proxy, etc…
    2. 未実装: Module,RegExp,Atomic, etc…

<!--
- NovaというRust製JavaScriptがあります。
- Novaが何かとか、なんで作っているか。みたいな話は、今日はしません。
- なのでよかったら貼ってあるリンクを見てください。
- 簡単に僕の口から説明をしておくと、Novaとは、Rust言語で書かれたJavaScriptのエンジンです。
- JavaScriptのエンジンは有名どころでいうと、v8,JavaScriptCore,SpiderMonkey,LibJS,Boaなどがあります。
- そして、ecma262に対してのテストであるtest262では今約66%ほど通っています。
- 今は、Array,Map,TypedArray,Proxyなどは大体動きますが、Module,RegExp,Atomicなどはまだ動かないです
-->

---

## JavaScript EngineでTypeScriptを実行する（🤔）

<!--
- さて、ここから本題のJavaScript EngineでTypeScriptを実行する話をします。
-->

---

## JavaScript EngineでTypeScriptを実行する（🤔）
Q. 以下のコードをブラウザで動かしてください。
```ts
const str: string = "TSKaigi 2025!!"
```

<!--
- 突然ですが、こちらのコードをブラウザで動かしてみて欲しいです。
-->

---

## JavaScript EngineでTypeScriptを実行する（🤔）
Q. 以下のコードをブラウザで実行してください。

```ts
const str: string = "TSKaigi 2025!!"
```

A. 型アノテーションはJavaScriptの構文ではないので構文エラーとなる。
（`Uncaught SyntaxError: Missing initializer in const declaration`）

<!--
- こちらはブラウザで実行するとエラーになります。
- なぜなら、型アノテーションはJavaScriptの構文ではないためです。
- 一応補足で、ブラウザで実行してもらったのはエラーを確認してもらうためです。エンジンを手元で用意してもらうとか大変だと思うので。
-->

---

## Novaでは
Novaでは、Rustのfeatureフラグを使用することでTypeScriptを実行できるようになっている

```ts
const str: string = "TSKaigi 2025!!"

$ cargo run --features typescript eval index.ts
$ andromeda run index.ts
```

<!--
- さて、ここからNovaの話です。Novaでは、Rustのfeatureフラグを仕様することで、TypeScriptを実行できる様になっています。
- なので、先ほどのコードも動きます。
- 手元でNovaをcloneしてもらって、実行するか、もしくはandromedaっていうランタイムもあるので、そちらを使ってもらって動かしてみてもらっても大丈夫です。
-->

---

## 実装コード

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

<!--
- 具体的な実装コードを少しみてみましょう。
- feature = typescriptと囲まれた中に、with_typescriptと書いています。このbooleanをtrueにしています。
- 実はこれだけです。
- ちなみにこれみていて気づいたんですが、with_jsxというのもあるみたいなので、色々やることはありますが、jsxも動かせる様になるかもしれないですね。
- 僕は必要だとは今は思わないですが、可能性があることはいいことです。
-->

---

## どのようにサポートしているのか？

- Parserにoxcを使用
- Parse後にJavaScriptエンジンなら当然、bytecodeにコンパイルする処理を書く必要がある
- TypeScript独自の構文であるenumやnamespaceも同様にJavaScript Engineが扱うならbytecodeにコンパイルさせる必要がある
- enumサポートはまだ途中（ https://github.com/trynova/nova/pull/598 ）

<!--
- 次に、どのようにサポートしているかです。
- まずParserにはoxcを使用しています。
- 先ほどのwith_typescriptやwith_jsxも、oxcのおかげで使えているという感じです。
- そしてこのparse後にJavaScriptエンジンなら当然、bytecodeにコンパイルする処理を書く必要があります。
- そしてTypeScript独自の構文であるenumやnamespaceも同様に、JavaScript Engineが扱うならbytecodeにコンパイルさせる必要があります。
- enumはやってみてと言われたので、途中まで書きました。あと少しでできるかなと思います。
-->

---

## 正式にサポートするの？

- わからない
- TypeScriptのサポートをメインに考えているわけではないので、ネイティブサポートするかはわからない
  - まずtest262を通すことが優先。
- strip-typesのサポートも聞いたら、「やってみたら動いた！」みたいな感じだった。
- なので誰か手が空いた人が進めていくみたいな感じにはなると思う。

<!--
- ではNovaが正式にTypeScriptサポートをするのでしょうか。
- まぁ本当にこれはわからないです。
- 少なくとも今現在のメインでやりたいことではない、はず。
- それ以上に現状はtest262を通していくことの方が大事。
- 現状のTSサポートも、聞いてみたら「やってみたら動いた！」みたいな感じだった。
- なので、誰か手が空いた人が進めていくみたいな感じにはなると思う。やってくれてもいい。
-->

---

## 個人的な意見

現状の開発において、TypeScriptを使わないことはありえなくなってきている（というかなっている）。
であれば、JS EngineがTypeScriptをネイティブで実行できるようにしても良いのかなと思う。
そしてその結果、あわよくば型情報を使った最適化を可能にし、よりJavaScriptが高速で動くことを期待したい。
