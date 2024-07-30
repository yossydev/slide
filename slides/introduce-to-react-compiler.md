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
- Field: Web Developer
- [X](https://twitter.com/yossydev)
- [Blog](https://yossy.dev/)
- [Youtube](https://www.youtube.com/@yossydev)

![bg right h:40%](./images/yossydev.jpg)

---

## Agenda

1. What is React
1. What is React Compiler
1. What makes the React Compiler happy?
1. React Compiler's HIR
1. Summary

---

# What is React

---

## What is React

Indispensable for today's web application development.
訳: 今のフロントエンド開発になくてはならないもの。

other tool

- Vue
- Svelte
- Astro
- SoildJS
- qwik

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

Developers have used the following React APIs for optimisation

- useMemo
- useCallback
- React.memo

---

## What is React Compiler

Developers have used the following React APIs for optimisation

~~- useMemo~~
~~- useCallback~~
~~- React.memo~~

**React Compiler does not use these and performs optimisations automatically!**

---

# What makes the React Compiler happy?

React Compilerは何が嬉しいの？

---

## What makes the React Compiler happy?

1. Manual memoization → Auto memoization
2. Code quality assurance through compilation checks

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

### Code quality assurance through compilation checks

Allow the compilation to fail if there is unintended/unauthorised code

---

### Code quality assurance through compilation checks

Example) Where do you think they fail?

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

### Code quality assurance through compilation checks

```tsx
function Component(props) {
  const items = [];
  for (const x of props.items) {
    // InvalidReact: Mutating component props or hook arguments is not allowed. Consider using a local variable instead (4:4)
    x.modified = true;
    items.push(x);
  }
  return items;
}
```

---

### Code quality assurance through compilation checks

Valid Code.

```tsx
function Component(props) {
  const modifiedItems = props.items.map((item) => ({
    ...item,
    modified: true,
  }));

  return (
    <ul>
      {modifiedItems.map((item, index) => (
        <li key={index}>{/* <div></div> */}</li>
      ))}
    </ul>
  );
}
```

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
```

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

他にも面白いものあるよ！（eslintSuppressionRules, opt-in/opt-out, HIR...）

---

# React19楽しみです！！！！！
