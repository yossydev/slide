---
marp: true
title: Fast JSX: Don't clone props object #28768
author: ユウト
keywords: marp,marp-cli,slide
paginate: true
---

# [Fast JSX: Don't clone props object #28768](https://github.com/facebook/react/pull/28768)

@yossydev

---

## Profile

- Name: ユウト
- Field: Web Developer
- Blog: [yossy.dev](https://yossy.dev/)
- SNS / Youtube: [@yossydev](https://twitter.com/yossydev)

![bg right h:40%](./images/yossydev.jpg)

---

## Agenda

1. 高速化のポイント
1. key, refの予約語をpropsからの削除
1. public apiであるcreateElement後のpropsの上書き
1. 実装を見る

---

# 高速化のポイント

---

# 高速化のポイント

## propsをクローンする必要がなくなった

---

# 高速化の要因

## propsをクローンする必要がなくなった

### ではなぜpropsをクローンする必要があったのか

1.  key, refの予約語をpropsからの削除
2.  public apiであるcreateElement後のpropsの上書き

---

# 1. key, refの予約語をpropsから削除すること

---

## 1. key, refの予約語をpropsから削除すること: keyとref

- key: リスト内の要素を一意に識別するためのプロパティ
- ref: コンポーネントのdom動作を行うことができるプロパティ

```tsx
// key
const numbers = [1, 2, 3, 4, 5];
const listItems = numbers.map((number) => (
  <li key={number.toString()} ref>
    {number}
  </li>
));

// ref
const FancyButton = React.forwardRef((props, ref) => (
  <button ref={ref} className="FancyButton">
    {props.children}
  </button>
));
```

---

## 1. key, refの予約語をpropsから削除すること

### 問題点

keyとrefをpropsで渡さないようにする必要があった。

```ts
    for (propName in config) {
      if (
        hasOwnProperty.call(config, propName) &&
        propName !== 'key' &&
        (enableRefAsProp || propName !== 'ref')
      ) {
        if (enableRefAsProp && !disableStringRefs && propName === 'ref') {
          props.ref = coerceStringRef(
            config[propName],
            ReactCurrentOwner.current,
            type,
          );
        } else {
          props[propName] = config[propName];
```

---

## 1. key, refの予約語をpropsから削除すること

### 解消方法

- React19からは`props.ref`でrefにアクセスできるようになるそう🎉🤞

  - 今までは`React.forwardRef`で囲む必要があった

  - このアップデートによりrefの問題は解消できた

- そしてkeyも元々スプレット構文を使わなければクローンはされないようになっていました。
  - スプレット構文を使わなければjsx関数の第三匹数に値が入る
  - keyの解決🎉 （スプレット構文使用時以外）

---

# 2. createElementがpublic apiである

---

## 2. createElementがpublic apiである

### createElementとは何か

React17以前で使われていたjsxをdomに変換するための関数。これは我々開発者がReactからimportして使用することもできる

```tsx
// jsx                                  // compiled jsx
function Greeting({ name }) {           function Greeting({ name }) {
  return (                                  return createElement(
    <h1 className="greeting">                   "h1",
      Hello <i>{name}</i>. Welcome!             { className: "greeting" },
    </h1>                                       "Hello ",
  );                                                createElement("i", null, name),
}                                                   ". Welcome!",

                                            );
                                        }
```

---

## 2. createElementがpublic apiである

### ユーザーによるpropsの上書き

ユーザーがpropsの上書きができてしまうので、予期しないバグが起きる恐れがある。

```ts
const props = { className: "my-div" };
const element2 = React.createElement("div", props);
props.className = "my-div-changed";
console.log(element2.props.className); // 'my-div-changed'
```

---

## 2. createElementがpublic apiである

### React17以降

createElementではなくjsx関数が使われるようになった。([React17におけるJSXの新しい変換を理解する](https://zenn.dev/uhyo/articles/react17-new-jsx-transform))

```tsx
// jsx                                  // compiled jsx
function Greeting({ name }) {           function Greeting({ name }) {
  return (                                  return _jsxs("h1", {
    <h1 className="greeting">                    className: "greeting",
      Hello <i>{name}</i>. Welcome!              children: ["Hello ", _jsx("i", { children: name }), ". Welcome!"]
    </h1>                                   });
  );                                    }
}
```

---

## 2. createElementがpublic apiである

> the new JSX runtime, jsx, is not a public API
> 翻訳: 新しいJSXランタイムjsxはパブリックAPIではない

jsx関数はpublic apiではないため、ユーザーによるpropsの上書きを考慮する必要がなくなった

---

## 2. createElementがpublic apiである

### 疑問点: the new JSX runtime, jsx, is not a public API

`react/jsx-runtime`からimportして使えるやーーん

```tsx
import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";

const Foo = () => {
  return _jsxs(
    "div",
    {
      children: [
        _jsx("p", { id: "a", children: "I am foo" }, void 0),
        _jsx("p", { children: "I am foo2" }, "b"),
      ],
    },
    void 0,
  );
};
```

---

## 2. createElementがpublic apiである

### 予想: the new JSX runtime, jsx, is not a public API

jsxのコメントを見た感じは、**使えない**ではなく**使ってもこっちは知らないよ**みたいなニュアンスなのかなと感じています。

```tsx
/**
 * Create a React element.
 *
 * You should not use this function directly. Use JSX and a transpiler instead.
 */
export function jsx(
  type: React.ElementType,
  props: unknown,
  key?: React.Key,
): React.ReactElement;
```

---

# 実装を見てみる

---

## 実装を見てみる

単純にfor分で回さなくてよくなったので早くなってそう...？？👀

```ts
// Before: configをfor分で回して条件に一致したconfigだけkeyで抽出してpropsのkeyに代入している
    for (propName in config) {
      if (
          ...
      ) {
        if (enableRefAsProp && !disableStringRefs && propName === 'ref') {
            ...
        } else {
          props[propName] = config[propName];

// After: configを直接propsに代入してReactElementに渡している
  let props;
  if (enableRefAsProp && disableStringRefs && !('key' in config)) {
    props = config;
```

---

## まとめ

今まではpropsをクローンする必要があった

### 1. key, refの予約語をpropsから削除すること

refはpropsで参照できるようになる、keyもスプレット構文を使わなければ問題なし！

### 2. createElemet後にpropsの上書き

React17からjsxという関数が使われていて、それは我々開発者が使うことを推奨していないようなので気にしないでヨシッ👉！

### 実装

今までfor...inでぐるぐる回していたところを単純にfor分で回さなくてよくなった

---

# Have a good development life!
