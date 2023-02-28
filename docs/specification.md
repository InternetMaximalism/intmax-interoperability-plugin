# Specification

サーバートラストで済む内容については（優先度低）と表示しています。

- [x] scroll 上にフラグを管理するためのコントラクト（フラグコントラクト）を用意する
（intmax が参照する scroll 上のコントラクトが 1 つ指定される）。
フラグたちは flag_id から bool への mapping でストレージに保管する。
- [x] フラグコントラクトには、各 flag_id がどのような送金内容を表すかについての mapping を用意する。
- [ ] block header に scroll_root を含める。scroll_root の値は、
新たに有効化された flag_id とその送金内容の組を Merkle tree と見做して計算する。
- [ ] （優先度低）既存の block に重複する flag_id があるかをチェックしなければならない。
これは今までに有効化された flag_id とそれが有効化された block_number の組からなる sparse Merkle tree を用意して
block 検証回路で利用する。
- [ ] scroll 上で送信されたトークンを受け取るためには deposit された資産と同様にして merge tx を実行する。
deposit_root の代わりに scroll_root を指定できるようにすれば良い。
- [ ] ただし、flag_id の merge を実行するためには、該当する資産が zero address に対して送金されていなければならない。
- [ ] そのことをを確認するために zero address に対する送金と flag_id を対応づける必要がある。
  scroll 上のフラグコントラクトには送金情報とともに zero address への送金 tx hash を合わせて記録する。
- [ ] 各 flag_id に対応する tx hash (merge key) の計算も deposit のときと同様にして二重マージを防ぐ。
