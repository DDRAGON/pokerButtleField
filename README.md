管理ツールも作りたいのでExpressで作っていこうかと。


サーバーとの通信について
POSTやGETでの通信が簡単なので良いのでないかと考えたが、
手番の通知など、サーバーからAIに向けてデータを送りたいこともあるため、webSocketが良いのではないか？
ということで、通信はwebSocketを考えている。
npm install --save-dev socket.io

どうやら、expressを使用しないAIの場合、socket-io-clientをインストールしないといけない？
pokerAiは別プロジェクトで作ろう


curl -d command=gameStart localhost:3000/admin





