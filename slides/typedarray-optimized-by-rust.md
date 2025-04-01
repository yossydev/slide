---
title: "Rust製JavaScriptエンジンのTypedArray builtinの最適化"
description: "ネイティブコードを使った最適化の話"
marp: true
theme: default
paginate: true
---

# Rust製JavaScriptエンジンのTypedArray built-inメソッドの最適化

2025/03/21 [fukuoka.ts #3](https://fukuoka-ts.connpass.com/event/347048/)

---

## Profile

- Name: Yuto Yoshino
- Field: Frontend Developer
- Blog: [yossy.dev](https://yossy.dev/)
- Contributor: [Nova](https://github.com/trynova/nova)&[Andromeda](https://github.com/tryandromeda/andromeda)

![bg right h:40%](./images/yossydev.jpg)

---

## 話すこと

- NovaとはRustで新しく作っているJavaScriptのエンジンのこと。みんなが知っているものだとv8とかJSCとかSpiderMonkeyとかのRust版。
- 一応AndromedaはNovaを使ったJavaScriptランタイムのこと。
- 最近Novaに`%TypedArray%.prototype.indexOf`([#556](https://github.com/trynova/nova/pull/556))と`%TypedArray%.prototype.reverse`([#593](https://github.com/trynova/nova/pull/593))の実装をした
- 今回はその最適化の話をします。
- そしてこのスライドは半分くらいAIに頼ってる

---

## TypedArrayとは？

<style scoped>
table { font-size: 14px; }
th, td { padding: 4px; }
p { font-size: 14px; }
</style>

型付きの配列。TypedArray自体は存在せず、以下のTypedArrayオブジェクトたちのことを総じてTypedArrayと呼んでいる。
**ちなみに登壇者はこれを記憶にある限りでは使ったことない。**

| Type                | Value Range                             | Size(bytes) | Web IDL type        |
|---------------------|-----------------------------------------|-------------|---------------------|
| `Int8Array`         | -128 to 127                             | 1           | `byte`              |
| `Uint8Array`        | 0 to 255                                | 1           | `octet`             |
| `Uint8ClampedArray` | 0 to 255                                | 1           | `octet`             |
| `Int16Array`        | -32768 to 32767                         | 2           | `short`             |
| `Uint16Array`       | 0 to 65535                              | 2           | `unsigned short`    |
| `Int32Array`        | -2147483648 to 2147483647               | 4           | `long`              |
| `Uint32Array`       | 0 to 4294967295                         | 4           | `unsigned long`     |
| `Float16Array`      | -65504 to 65504                         | 2           | N/A                 |
| `Float32Array`      | -3.4e38 to 3.4e38                       | 4           | `unrestricted float`|
| `Float64Array`      | -1.8e308 to 1.8e308                     | 8           | `unrestricted double`|
| `BigInt64Array`     | -2^63 to 2^63 - 1                       | 8           | `bigint`            |
| `BigUint64Array`    | 0 to 2^64 - 1                           | 8           | `bigint`            |

ref: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray#typedarray_objects

---

## TypedArray.prototype.indexOfとは？

引数に渡された値のインデックスを返すメソッド。

```js
const uint8 = new Uint8Array([10, 20, 30, 40, 50]);

uint8.indexOf(50); // => 4
uint8.indexOf(51); // => -1
```

Arrayの`indexOf`と同じだが、扱うデータ型がTypedArray専用。

---

## 仕様書に基づく動作

仕様書では、要素を順番に確認するループを実行

```pseudo
11. Repeat, while k < len,
    a. Let Pk be ! ToString(𝔽(k)).
    b. Let kPresent be ! HasProperty(O, Pk).
    c. If kPresent is true, then
       i. Let elementK be ! Get(O, Pk).
       ii. If IsStrictlyEqual(searchElement, elementK) is true, return 𝔽(k).
    d. Set k to k + 1.
```

---

## 最初の実装

仕様書通り愚直な実装（Rust）

```rust
// 11. Repeat, while k < len,
while k < len {
    // a. Let kPresent be ! HasProperty(O, ! ToString(𝔽(k))).
    let k_present = has_property(...)?;
    // b. If kPresent is true, then
    if k_present {
        //  i. Let elementK be ! Get(O, ! ToString(𝔽(k))).
        let element_k = unwrap_try(try_get(...));
        //  ii. If IsStrictlyEqual(searchElement, elementK) is true, return 𝔽(k).
        if is_strictly_equal(agent, search_element, element_k) {
            return Ok(k.try_into().unwrap());
        }
    }
    // c. Set k to k + 1.
    k += 1
}
```

---

### 測ってみる

値が0の要素が1000万個作られ、それに対してindexOfは9999999を指定している

```js
const SIZE = 10_000_000;
const arr = new Uint32Array(SIZE);
arr.indexOf(9999999);
```

```
❯ time cargo run eval index.js
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.08s
     Running `target/debug/nova_cli eval index.js`
cargo run eval index.js  16.88s user 0.29s system 96% cpu 17.724 total
```

---

## ネイティブコードによる最適化のアイデア

- TypedArrayは型（u8/i16/f32など）が明確
- Rustのネイティブメソッドを利用可能
- スライス化してネイティブ検索が高速

---

## 最適化の具体的方法

1. TypedArrayのバイト列を取得
2. Rustの`align_to`で型変換
3. `iter().position()`を利用した高速検索

```rust
let byte_slice = array_buffer.as_slice(agent);
let (head, slice, _) = unsafe { byte_slice.align_to::<T>() };
if !head.is_empty() { /* error handling */ }

slice[k..len].iter().position(|&r| r == search_element)
```

---

## ベンチマーク結果

```js
const SIZE = 10_000_000;
const arr = new Uint32Array(SIZE);
arr.indexOf(9999999);
```

| 状態     | 実行時間     |
| -------- | ------------ |
| 最適化前 | 約17秒       |
| 最適化後 | 約0.6秒      |
| 改善効果 | 約28倍高速化 |

CPU使用率も大幅低下

---

## TypedArray.prototype.reverseとは？

配列の順番を逆にするメソッド

```js
const uint8 = new Uint8Array([10, 20, 30, 40, 50]);

uint8.reverse(); // [50, 40, 30, 20, 10]
```

Arra.prototype.reverseと一緒。

---

## 仕様書に基づく動作

<style scoped>
p { font-size: 16px; }
</style>

仕様書では、要素を順番に確認するループを実行

```pseudo
4. Let middle be floor(len / 2).
5. Let lower be 0.
6. Repeat, while lower ≠ middle,
   a. Let upper be len - lower - 1.
   b. Let upperP be ! ToString(𝔽(upper)).
   c. Let lowerP be ! ToString(𝔽(lower)).
   d. Let lowerValue be ! Get(O, lowerP).
   e. Let upperValue be ! Get(O, upperP).
   f. Perform ! Set(O, lowerP, upperValue, true).
   g. Perform ! Set(O, upperP, lowerValue, true).
   h. Set lower to lower + 1.
```

length - 1がその配列の最大値、そしてそこからlower文を引くので、ループするたびに最大値から一個少なくなる。
ループ時点での最初の値を最後に、最後の値を最初に持ってくるようにsetする。

---

## 最初の実装

<style scoped>
p { font-size: 16px; }
</style>

```rust
while lower != middle {
    // a. Let upper be len - lower - 1.
    let upper = len - lower - 1;
    // b. Let upperP be ! ToString(𝔽(upper)).
    let upper_p = PropertyKey::Integer(upper.try_into().unwrap());
    // c. Let lowerP be ! ToString(𝔽(lower)).
    let lower_p = PropertyKey::Integer(lower.try_into().unwrap());
    // d. Let lowerValue be ! Get(O, lowerP).
    let lower_value = unwrap_try(try_get(...));
    // e. Let upperValue be ! Get(O, upperP).
    let upper_value = unwrap_try(try_get(...));
    // f. Perform ! Set(O, lowerP, upperValue, true).
    try_set(...);
    // g. Perform ! Set(O, upperP, lowerValue, true).
    try_set(...);
    // h. Set lower to lower + 1.
    lower += 1;
}
```

---

## 最適化の具体的方法

1. TypedArrayのバイト列を取得
2. mutableなsliceを生成
2. Rustの`align_to_mut`で型変換
3. ネイティブ`reverse`を利用した高速変換

```rust
let byte_slice = array_buffer.as_mut_slice(agent);
let (head, slice, _) = unsafe { byte_slice.align_to_mut::<T>() };
let slice = &mut slice[..len];
slice.reverse();
```

---

## ベンチマーク結果

```js
const SIZE = 10_000_000;
const arr = new Uint32Array(SIZE);
arr.indexOf(9999999);
```

| 状態     | 実行時間     |
| -------- | ------------ |
| 最適化前 | 約18秒       |
| 最適化後 | 約0.5秒      |
| 改善効果 | 約36倍高速化 |

---

## まとめ

- JavaScriptエンジンの最適化の一つにネイティブコードを使うという方法
- 今回はRustだけど、多分C++でも似たようなことやってるのかなと思う
- 最適化しようとすると、JSのいろんな動きを考慮する必要が出てくるのでとても楽しい

ご静聴ありがとうございました。
