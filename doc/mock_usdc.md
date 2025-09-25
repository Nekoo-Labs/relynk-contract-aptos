
<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min"></a>

# Module `0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a::mock_usdc_min`



-  [Struct `MockUSDC`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_MockUSDC)
-  [Resource `Caps`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_Caps)
-  [Constants](#@Constants_0)
-  [Function `init`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_init)
-  [Function `register`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_register)
-  [Function `mint_to`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_mint_to)
-  [Function `transfer`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_transfer)
-  [Function `balance_of`](#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_balance_of)


<pre><code><b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_MockUSDC"></a>

## Struct `MockUSDC`

Token type (6 desimal)


<pre><code><b>struct</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_MockUSDC">MockUSDC</a> <b>has</b> store
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_Caps"></a>

## Resource `Caps`

store capabilities on @relynk


<pre><code><b>struct</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_Caps">Caps</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_E_NOT_AUTH"></a>



<pre><code><b>const</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_E_NOT_AUTH">E_NOT_AUTH</a>: u64 = 1;
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_init"></a>

## Function `init`



<pre><code><b>public</b> entry <b>fun</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_init">init</a>(admin: &<a href="">signer</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_register"></a>

## Function `register`

Register CoinStore<MockUSDC> (must be able to receive)


<pre><code><b>public</b> entry <b>fun</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_register">register</a>(user: &<a href="">signer</a>)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_mint_to"></a>

## Function `mint_to`

Mint to address (admin @relynk)


<pre><code><b>public</b> entry <b>fun</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_mint_to">mint_to</a>(admin: &<a href="">signer</a>, <b>to</b>: <b>address</b>, amount: u64)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_transfer"></a>

## Function `transfer`

Transfer (sender signs themselves)


<pre><code><b>public</b> entry <b>fun</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_transfer">transfer</a>(sender: &<a href="">signer</a>, <b>to</b>: <b>address</b>, amount: u64)
</code></pre>



<a id="0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_balance_of"></a>

## Function `balance_of`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="mock_usdc.md#0xefa490deb584bf7423c8fdd1b5a06c869d99bbe4608ba5edfb6ed1fc63b3294a_mock_usdc_min_balance_of">balance_of</a>(owner: <b>address</b>): u64
</code></pre>
