---
marp: true
title: Introduction to React Compiler
author: ユウト
keywords: marp,marp-cli,slide
paginate: true
---

# Introduction to React Compiler

[@yossydev](https://twitter.com/yossydev)

---

## Profile

- Name: ユウト
- Field: Web Frontend Developer
- [X](https://twitter.com/yossydev)
- [Bluesky](https://bsky.app/profile/yossydev.com)
- [Blog](https://yossy.dev/)
- [Youtube](https://www.youtube.com/@yossydev)

![bg right h:40%](./images/yossydev.jpg)

---

## Agenda

1. What is React
1. What is React Compiler
1. What makes the React Compiler happy?
1. ~~React Compiler's HIR~~
1. Summary

---

# What is React

Reactとは？

---

## What is React

Libraries that make it easier for developers to create web apps.
訳: Webアプリを開発者が作りやすいようにしてくれるライブラリ

other tool

- Vue
- Svelte
- Astro
- SoildJS
- Qwik
- HonoX

---

# What is React Compiler

React Compilerとは？

---

## What is React Compiler

> React Compiler is a compiler that optimizes React applications, ensuring that only the minimal parts of components and hooks will re-render when state changes. The compiler also validates that components and hooks follow the Rules of React.
> https://github.com/facebook/react/blob/main/compiler/README.md

**React Compiler is a compiler that optimizes React applications**
訳: React CompilerはReactアプリケーションを最適化するコンパイラ

---

## What is React Compiler

Foo is re-rendered every time a button is clicked.
訳: buttonをクリックするたびにFooが再レンダリングされてしまう

```tsx
const App = () => {
  const [count, setCount] = useState(0);
  return (
    <>
      <button onClick={() => setCount((count) => count + 1)}>
        count is {count}
      </button>
      <Foo />
    </>
  );
};

// Not memoised.
const Foo = () => {
  console.log("レンダリング！");
  return <></>;
};
```

---

## What is React Compiler

Developer memoing to prevent unnecessary re-rendering.
訳: 開発者がメモ化して不要な再レンダリングを防ぐ

```tsx
const App = () => {
  const [count, setCount] = useState(0);
  return (
    <>
      <button onClick={() => setCount((count) => count + 1)}>
        count is {count}
      </button>
      <Foo />
    </>
  );
};

// Not memoised.
const Foo = memo(() => {
  console.log("レンダリング！");
  return <></>;
});
```

---

## What is React Compiler

React basically re-renders everything, so use the following API to optimise (memoise)
訳: Reactは基本的に全てを再レンダリングするので、以下のAPIを使って最適化（メモ化）を行なう

- useMemo
- useCallback
- React.memo

---

## What is React Compiler

**React Compiler does not use these and performs optimisations automatically!**
訳: React Compilerはこれらを使用せず、自動的に最適化を行います！

~~- useMemo~~
~~- useCallback~~
~~- React.memo~~

---

# What makes the React Compiler happy?

React Compilerは何が嬉しいの？

---

## What makes the React Compiler happy?

1. Manual memoization → Auto memoization
2. Code can be checked by the compiler.

---

# Manual memoization → Auto memoization

手動メモ化 → 自動メモ化

---

### Manual memoization → Auto memoization

Example)

```tsx
import { useState } from "react";

export default function MyApp() {
  const [name, setName] = useState("");
  const [address, setAddress] = useState("");

  const handleSubmit = (orderDetails) => {
    setAddress("122-2222");
    post("/product/" + productId + "/buy", {
      referrer,
      orderDetails,
    });
  };
  j;

  const visibleTodos = () => filterTodos(todos, tab);

  return (
    <>
      <p>{address}</p>
      <Greeting name={"Yuto"} />
      <button onClick={visibleTodos}>Click!!</button>
      <button onClick={handleSubmit}>Click!!</button>
    </>
  );
}

function Greeting({ name }) {
  console.log("Greeting was rendered at", new Date().toLocaleTimeString());
  return (
    <h3>
      Hello{name && ", "}
      {name}!
    </h3>
  );
}
```

---

### Manual memoization → Auto memoization

Example) part of one

```tsx
function MyApp() {
  const $ = _c(8);
  ...other
  const handleSubmit = t0;
  const visibleTodos = _temp;
  let t2;
  let t3;
  let t4;
  if ($[3] === Symbol.for("react.memo_cache_sentinel")) {
    t2 = <Greeting name="Yuto" />;
    t3 = <button onClick={visibleTodos}>Click!!</button>;
    t4 = <button onClick={handleSubmit}>Click!!</button>;
    $[3] = t2;
    $[4] = t3;
    $[5] = t4;
  } else {
    t2 = $[3];
    t3 = $[4];
    t4 = $[5];
  }
  return t5;
}
...other
```

---

### Manual memoization → Auto memoization

Example) part of one

```tsx
function MyApp() {
  const $ = _c(8); // Generate an Array with a capacity of 8
  ...other
  const handleSubmit = t0;
  const visibleTodos = _temp;
  let t2;
  let t3;
  let t4;
  if ($[3] === Symbol.for("react.memo_cache_sentinel")) { // Cache if Symbol.for("react.memo_cache_sentinel") is true.
    t2 = <Greeting name="Yuto" />;
    t3 = <button onClick={visibleTodos}>Click!!</button>;
    t4 = <button onClick={handleSubmit}>Click!!</button>;
    $[3] = t2;
    $[4] = t3;
    $[5] = t4;
  } else { // If Symbol.for("react.memo_cache_sentinel") is false, return cached results.
    t2 = $[3];
    t3 = $[4];
    t4 = $[5];
  }
  return t5;
}
...other
```

---

### Manual memoization → Auto memoization

For me, it's good that this reduces communication about whether to memoise or not.
訳: メモ化するしないのコミュニケーションも減らせる

a. 「Is memoing here necessary?」

b. 「Necessary because 〇〇 is 〇〇」

---

# Code can be checked by the compiler

コンパイラによるコードのチェックができる

---

### Code can be checked by the compiler

Question) Do you think this code is an error?
訳: このコードはエラーになると思いますか？

```tsx
function Component(props) {
  const items = [];
  for (const x of props.items) {
    x.modified = true;
    items.push(x);
  }
  return items;
}
```

---

### code can be checked by the compiler

Answer) Compilation error!
`InvalidReact: Mutating component props or hook arguments is not allowed. Consider using a local variable instead (4:4)`

```tsx
function Component(props) {
  const items = [];
  for (const x of props.items) {
    x.modified = true;
    items.push(x);
  }
  return items;
}
```

---

### Code can be checked by the compiler

他にもエラーになるケースはたくさんあります！[playground](https://playground.react.dev/#N4Igzg9grgTgxgUxALhAMygOzgFwJYSYAEAwhALYAOhCmOAFJTBJWAJRHAA6xRchYHETw4E5MEQC8RANoBdANw8iRNBBhF6-TIKIAPIhDREmLMADoRY9p2Ur958hAAmeNHgTOpRHDCgIlXhUrcXNKKDAAC3o9NkCVAF87GAQcWGIQsECkzBAEoA)を触ったり、[テストケース](https://github.com/facebook/react/tree/main/compiler/packages/babel-plugin-react-compiler/src/__tests__/fixtures/compiler)を見たりしてみてください！

<!--
# About React Compiler`s HIR

---

## About React Compiler`s HIR

### BuildHIR Step

1. Parse By Babel
2. Build AST
3. Build HIR from AST

### What is HIR

HIR preserves the high-level code structure, but converts it into a format that is easy for the compiler to handle. It is influenced by the Rust Compiler Development Guide.

訳) HIRは、高レベルなコード構造を保持しつつ、コンパイラが扱いやすい形式に変換したものです。これはRust Compiler Development Guideから影響を受けています。

---

## About React Compiler`s HIR

### Why HIR?

> High-level code is more compact, and helps reduce the impact of compilation on application size
>
> High-level constructs that match what the developer wrote are easier to debug

訳)

- 高レベルなコード構造を維持することで、コンパイル後のアプリケーションサイズへの影響を最小限に抑える
- 開発者が書いたコードの構造に近い形を保持するため、デバッグが容易になる

---

## About React Compiler`s HIR

Example JavaScript Code

```js
a ?? b;
````

- this code is **if a is nullabe then return b**
- React Compiler wants to use this code because of this is not change `if`

---

## About React Compiler`s HIR

Example JavaScript Code

```js
a ?? b;
```

- this code is **if a is nullabe then return b**
- React Compiler wants to use this code because of this is not change `if`

-->

---

# まとめ

---

## まとめ

- React CompilerがReact19から入る
- 自動で最適化を行ってくれたり、変なコードはコンパイルエラーを出してくれるようになる
- 特段何か設定する必要はない
  - babelプラグインとして使う
  - フレームワーク側の設定に合わせる

他にも面白いものあるよ！（eslintSuppressionRules, opt-in/opt-out, HIR...）

---

# React19楽しみです！！！！！
