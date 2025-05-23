---
title: "Rust製JavaScript EngineのTypeScriptサポート"
description: "近年、TypeScriptは広く普及し、主要なJavaScriptランタイムも対応を進めています。しかし、これらはあくまでランタイム側でのサポートであり、エンジン自体がTypeScriptを直接実行するわけではありません。本LTでは、Rust製JavaScriptエンジン Nova におけるTypeScript実行の取り組みを紹介し、エンジンレベルでのTypeScriptサポートの可能性について考察します。"
marp: true
theme: default
paginate: true
---

# Rust製JavaScript EngineのTypeScriptサポート

2025/05/23 [tskaigi 2025](https://2025.tskaigi.org/talks/yossydev)

<!--
スライド
-->

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
- タイトルにあるRust製JavaScriptとはNovaのことを指しています。
- Novaが何かとか、なんで作っているか。みたいな話は、今日はしません。
- なのでよかったら貼ってあるリンク、Why build a JavaScript engine/What is the Nova JavaScript engineを見てください。
- さらに時間がないので、結構色々な説明を省いています。後で調べるか聞くかしてください。
- 簡単に僕の口から説明をしておくと、Novaとは、Rust言語で書かれたJavaScriptのエンジンです。
- JavaScriptのエンジンは有名どころでいうと、v8,JavaScriptCore,SpiderMonkey,LibJS,Boaなどがあります。
- このNovaは、ecma262に対してのテストであるtest262は、今約66%ほど通っています。
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
- 最初のwith_moduleとかwith_scirptとかは無視してもらって、次のところですね。
- feature = typescriptと囲まれた中に、with_typescript: trueと書いています。
- 実は先ほどの型アノテーションだけなら、これだけで動作します。理由は後で話します。
- あと、コードを読んでていて気づいたんですが、with_jsxというのもあるみたいです。
- これを使えば、色々やることはありそうだしあると思いますが、jsxもengineで処理できる様になるかもしれないですね。
- engineのjsx実行は僕は必要だとは思わないですが、可能性があることはいいことです。
-->

---

## どのようにサポートしているのか？

- Parserにoxcを使用
  ```rs
  // nova_vm/src/ecmascript/scripts_and_modules/source_code.rs#L95
  let parser = Parser::new(..., source_text, source_type);
  ```
- Parse後に、JavaScriptエンジンなら当然、bytecodeにコンパイルする処理を書く必要がある
- TypeScript独自の構文であるenumやnamespaceも同様にJavaScriptエンジンが扱うならbytecodeにコンパイルさせる必要がある
- enumのbytecodeコンパイルは実装途中（ [#598](https://github.com/trynova/nova/pull/598) ）

<!--
- 次に、どのようにサポートしているかです。
- まず、Parserにはoxcを使用しています。
- 先ほどのwith_typescriptやwith_jsxも、oxcのapiとして提供されているので使えているという感じです。
- Parser:newってところで、source_typeを渡しているかと思いますが、ここのwith_typescriptみたいなオプションが入ってきます。
- source_textはsource_textです。
- そしてこのparse後に、JavaScriptエンジンなら当然、bytecodeにコンパイルする処理を書く必要があります。
- ここでポイントなのは、TypeScript独自の構文であるenumやnamespaceも同様に、JavaScript Engineが扱うならbytecodeにコンパイルさせる必要があります。
- enumはやってみてと言われたので、動かすだけなら、後少しでできるかなと思います、途中まで書きました。
-->

---

## 正式にサポートするの？

- わからない🤷‍♂️
- TypeScriptのサポートをメインに考えているわけではないので、本格的にサポートするかはわからない
  - まずtest262を通すことが優先。
- 現状のTypeScriptサポートも聞いたら、「やってみたら動いた！」みたいな感じだった。
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

<!--
スライド
-->
