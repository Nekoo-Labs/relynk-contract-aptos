
<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1"></a>

# Module `0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a::paymentv1`



-  [Struct `PaymentProcessed`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_PaymentProcessed)
-  [Struct `TransferLinkCreated`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLinkCreated)
-  [Struct `TransferClaimed`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferClaimed)
-  [Resource `EscrowCapability`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_EscrowCapability)
-  [Resource `TransferLinkStore`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLinkStore)
-  [Struct `TransferLink`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLink)
-  [Constants](#@Constants_0)
-  [Function `init`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_init)
-  [Function `ensure_store`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_ensure_store)
-  [Function `process_payment`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_process_payment)
-  [Function `create_transfer_with_link`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_create_transfer_with_link)
-  [Function `claim_transfer`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_claim_transfer)
-  [Function `get_transfer_link_info`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_get_transfer_link_info)
-  [Function `is_token_supported`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_is_token_supported)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::aptos_coin</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::table</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::type_info</a>;
<b>use</b> <a href="supported_tokens.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_supported_tokens">0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a::supported_tokens</a>;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_PaymentProcessed"></a>

## Struct `PaymentProcessed`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_PaymentProcessed">PaymentProcessed</a> <b>has</b> drop, store
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLinkCreated"></a>

## Struct `TransferLinkCreated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLinkCreated">TransferLinkCreated</a> <b>has</b> drop, store
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferClaimed"></a>

## Struct `TransferClaimed`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferClaimed">TransferClaimed</a> <b>has</b> drop, store
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_EscrowCapability"></a>

## Resource `EscrowCapability`



<pre><code><b>struct</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_EscrowCapability">EscrowCapability</a> <b>has</b> key
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLinkStore"></a>

## Resource `TransferLinkStore`



<pre><code><b>struct</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLinkStore">TransferLinkStore</a>&lt;T&gt; <b>has</b> key
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLink"></a>

## Struct `TransferLink`



<pre><code><b>struct</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_TransferLink">TransferLink</a>&lt;T&gt; <b>has</b> store
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_NOT_AUTHORIZED"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_NOT_AUTHORIZED">E_NOT_AUTHORIZED</a>: u64 = 7;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_INSUFFICIENT_BALANCE"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_INSUFFICIENT_BALANCE">E_INSUFFICIENT_BALANCE</a>: u64 = 3;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_INVALID_AMOUNT"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_INVALID_AMOUNT">E_INVALID_AMOUNT</a>: u64 = 2;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_ALREADY_CLAIMED"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_ALREADY_CLAIMED">E_LINK_ALREADY_CLAIMED</a>: u64 = 5;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_ALREADY_EXISTS"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_ALREADY_EXISTS">E_LINK_ALREADY_EXISTS</a>: u64 = 8;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_EXPIRED"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_EXPIRED">E_LINK_EXPIRED</a>: u64 = 6;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_NOT_FOUND"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_LINK_NOT_FOUND">E_LINK_NOT_FOUND</a>: u64 = 4;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_TOKEN_NOT_SUPPORTED"></a>



<pre><code><b>const</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_E_TOKEN_NOT_SUPPORTED">E_TOKEN_NOT_SUPPORTED</a>: u64 = 1;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_init"></a>

## Function `init`



<pre><code><b>public</b> entry <b>fun</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_init">init</a>(admin: &<a href="">signer</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_ensure_store"></a>

## Function `ensure_store`



<pre><code><b>public</b> entry <b>fun</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_ensure_store">ensure_store</a>&lt;T: store&gt;(admin: &<a href="">signer</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_process_payment"></a>

## Function `process_payment`



<pre><code><b>public</b> entry <b>fun</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_process_payment">process_payment</a>&lt;T: store&gt;(payer: &<a href="">signer</a>, recipient: <b>address</b>, amount: u64, payment_id: <a href="_String">string::String</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_create_transfer_with_link"></a>

## Function `create_transfer_with_link`



<pre><code><b>public</b> entry <b>fun</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_create_transfer_with_link">create_transfer_with_link</a>&lt;T: store&gt;(sender: &<a href="">signer</a>, link_id: <a href="_String">string::String</a>, amount: u64, expires_in_hours: u64)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_claim_transfer"></a>

## Function `claim_transfer`



<pre><code><b>public</b> entry <b>fun</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_claim_transfer">claim_transfer</a>&lt;T: store&gt;(claimer: &<a href="">signer</a>, link_id: <a href="_String">string::String</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_get_transfer_link_info"></a>

## Function `get_transfer_link_info`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_get_transfer_link_info">get_transfer_link_info</a>&lt;T&gt;(link_id: <a href="_String">string::String</a>): (<b>address</b>, u64, u64, u64, bool)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_is_token_supported"></a>

## Function `is_token_supported`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="payment.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_paymentv1_is_token_supported">is_token_supported</a>&lt;T&gt;(): bool
</code></pre>
