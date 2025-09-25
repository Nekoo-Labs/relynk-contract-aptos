
<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens"></a>

# Module `0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a::supported_tokens`



-  [Resource `SupportedTokens`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_SupportedTokens)
-  [Constants](#@Constants_0)
-  [Function `add_supported_token`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_add_supported_token)
-  [Function `remove_supported_token`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_remove_supported_token)
-  [Function `is_supported`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_is_supported)
-  [Function `assert_supported`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_assert_supported)


<pre><code><b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::table</a>;
<b>use</b> <a href="">0x1::type_info</a>;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_SupportedTokens"></a>

## Resource `SupportedTokens`

Resource for storing token allowlist


<pre><code><b>struct</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_SupportedTokens">SupportedTokens</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_E_NOT_AUTHORIZED"></a>

Errors


<pre><code><b>const</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_E_NOT_AUTHORIZED">E_NOT_AUTHORIZED</a>: u64 = 1;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_E_NOT_INITIALIZED"></a>



<pre><code><b>const</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_E_NOT_INITIALIZED">E_NOT_INITIALIZED</a>: u64 = 3;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_E_NOT_SUPPORTED"></a>



<pre><code><b>const</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_E_NOT_SUPPORTED">E_NOT_SUPPORTED</a>: u64 = 2;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_add_supported_token"></a>

## Function `add_supported_token`

Add/allow Coin<T> (generic, without sending TypeInfo from outside)


<pre><code><b>public</b> entry <b>fun</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_add_supported_token">add_supported_token</a>&lt;T&gt;(admin: &<a href="">signer</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_remove_supported_token"></a>

## Function `remove_supported_token`

Remove/disable Coin<T> (set to false, don't delete entry)


<pre><code><b>public</b> entry <b>fun</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_remove_supported_token">remove_supported_token</a>&lt;T&gt;(admin: &<a href="">signer</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_is_supported"></a>

## Function `is_supported`

Query: is Coin<T> allowed?


<pre><code><b>public</b> <b>fun</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_is_supported">is_supported</a>&lt;T&gt;(registry_owner: <b>address</b>): bool
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_assert_supported"></a>

## Function `assert_supported`

Guard: call at the beginning of entry functions that accept assets


<pre><code><b>public</b> <b>fun</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens_assert_supported">assert_supported</a>&lt;T&gt;(registry_owner: <b>address</b>)
</code></pre>
