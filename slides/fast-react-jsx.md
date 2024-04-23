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
- SNS: [@yossydev](https://twitter.com/yossydev)

![bg right h:40%](./images/yossydev.jpg)

---

## Agenda

1. Previous JSX in React.
   1. key, refの予約語をpropsから削除すること
   2. createElementがpublic apiである
2. How speeding up works from an implementation point of view

---

# Previous JSX in React.

---

## 1. key, refの予約語をpropsから削除すること

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

`createElemet` is 何？ → React17以前で使われていたjsxをdomに変換するための関数

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
