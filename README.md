# EDCB-Linux Docker

[tkntrec版 EDCB](https://github.com/tkntrec/EDCB)および[BonDriver_LinuxMirakc](https://github.com/matching/BonDriver_LinuxMirakc) を組み込んだDocker環境です．すでに別環境やLAN内で起動している Mirakurun / Mirakc と接続して動作させることができるほか，ホストマシンにチューナーが接続されている場合は，本Docker環境上でそのまま[Mirakurun](https://github.com/chinachu/mirakurun)コンテナを起動して一括で運用することも可能です．

tsukumijima氏の[KonomiTV](https://github.com/tsukumijima/KonomiTV)との連携を前提として構築されており，Gitのサブモジュールとして取り込むことで，EDCBによる録画管理とKonomiTVによる視聴環境をまとめて起動することができます(注: このプロジェクトはKonomiTVとは一切の関係がありません)．KonomiTVに関しての設定は非常に複雑なので，一度[公式Readme](https://github.com/tsukumijima/KonomiTV)を読んでからの構築を強く推奨します．

このリポジトリでの初期設定は，`./data`以下に番組表データ等のEDCBのデータ，録画データとサムネイルを保存するようになっています．適宜，`docker-compose.yaml`のマウント先をNAS等に変更して下さい．

## インストール方法

### リポジトリのクローン
```bash
# 新規クローンする場合
git clone --recurse-submodules https://github.com/gigaonion/EDCB-Linux.git
cd EDCB-Linux

# すでにクローン済みでサブモジュールを初期化・更新する場合
git submodule update --init --recursive
```

### EDCB 設定の調整

`config/BonDriver_LinuxMirakc.so.ini`の`SERVER_HOST`および`SERVER_PORT`をmirakc/Mirakurunの接続先IPに合わせて編集します（Mirakurunコンテナを一緒に起動する場合は変更の必要はありません）．

```ini
[GLOBAL]
SERVER_HOST="192.168.x.x"
SERVER_PORT=40772
```

また，`config/EpgTimerSrv.ini`の，チューナー数をMirakurun / Miracの環境に合わせて変更します．
```ini
[BonDriver_LinuxMirakc(LinuxMirakc).so]
; チューナーの数に応じて変更
Count=2
; GetEpgはチューナー数の半分目安
GetEpg=1
```
### KonomiTVの設定
`konomi-config.yaml`の設定を行います．最低限はmirakurun_urlを編集すれば動くはずですが，快適度のために，エンコード周りを自身の設定に合わせて変更することを推奨します．また，このプロジェクトでは，KonomiTVの仕様変更への追従が難しい可能性があります．公式ドキュメントを確認の上での構築を**強く推奨します**．

```yaml
mirakurun_url: 'http://mirakurun:40772/
```

### docker-compose.yamlの編集
既に他にMirakurunが起動している場合は，mirakurunのセクションを丸ごと削除します．
```yaml
services:
# ここから
  mirakurun:
    image: chinachu/mirakurun:${MIRAKURUN_IMAGE_TAG:-latest}
#～～中略～～
    logging:
      driver: json-file
      options:
        max-file: "1"
        max-size: 10m
# ここまで
```
また，マウントポイントをご自身の環境に合わせて変更してください．

- EDCB 領域
  - `./config` ➔ `/etc/edcb/user_config` (設定ファイル)
  - `./data/edcb` ➔ `/var/local/edcb/data` (EPG・番組表データ)
  - `./data/rec` ➔ `/rec` (録画ファイル保存先)

- KonomiTV 領域
  - `./KonomiTV/config.yaml` ➔ `/code/config.yaml`
  - `./KonomiTV/server/data/` ➔ `/code/server/data/`
  - `./KonomiTV/server/logs/` ➔ `/code/server/logs/`
  - `./data/rec` ➔ `/host-rootfs/rec` (録画フォルダマウント)
  - `./data/pic` ➔ `/host-rootfs/pic` (サムネイル等保存先)


### コンテナの起動
まず，KonomiTVをビルドした後，起動します．

```bash
docker compose build konomitv && docker compose up -d
```

### 初回チャンネル設定・チャンネルスキャン
本リポジトリは，MirakurunとEDCBを使用する関係で，スキャンを2回行う必要があります．
#### Mirakurn
`http://<ホストマシンのIPアドレス>:40772/config/channels`をブラウザで開き，スキャンを開始します．
#### EDCB
ご自身の利用環境に合わせて，以下のいずれかの方法でチャンネル設定を行ってください．

1. 既存のチャンネル設定ファイルを配置する場合
   ご自身の環境で作成した`ChSet4.txt` / `ChSet5.txt`や`BonDriver_LinuxMirakc(LinuxMirakc).ChSet4.txt`などの設定ファイルを`./config/Setting/`ディレクトリ内に配置してからコンテナを起動してください．

2. 初回起動後に EPG 取得・スキャンを行う場合
   コンテナを起動後，ホストマシンのターミナルから以下のコマンドを実行してチャンネルスキャンを開始し，完了したら，コンテナを再起動します．

```bash
docker exec -it edcb /usr/local/bin/EpgDataCap_Bon -d BonDriver_LinuxMirakc.so -chscan
docker restart edcb
```

再起動後，EDCBのWeb UI（`http://<ホストマシンのIPアドレス>:5510`）にアクセスし，EPG 取得を実行して番組表データを取得してください．


## ライセンス&クレジット

### 本リポジトリのライセンス
本リポジトリ内の独自構成スクリプト・ドキュメントは[MIT License](./LICENSE)のもとで公開されています．

### 謝辞

本リポジトリは，以下のオープンソースプロジェクトを組み込み・連携して構成されています．
リポジトリの維持と，DTVコミュニティの発展への多大なご貢献に心より感謝申し上げます．

- [Mirakurun](https://github.com/chinachu/mirakurun)
  - 開発者: Chinachu 氏 ([Apache-2.0 license](https://github.com/chinachu/mirakurun/blob/master/LICENSE))
- [EDCB (tkntrec 版)](https://github.com/tkntrec/EDCB)
  - 開発者: xtne6 氏, xtne6f 氏, tkntrec 氏 ほか開発者の皆様
  - ライセンス: xtne6氏の利用規約により非商用・フリーソフト限定と規定されています．本リポジトリ全体の環境を利用・再配布する際はご注意ください．
- [BonDriver_LinuxMirakc](https://github.com/matching/BonDriver_LinuxMirakc)
  - 開発者: matching 氏 ([MIT License](https://github.com/matching/BonDriver_LinuxMirakc/blob/master/LICENSE))
- [KonomiTV](https://github.com/tsukumijima/KonomiTV)
  - 開発者: tsukumijima 氏 ([MIT License](https://github.com/tsukumijima/KonomiTV/blob/master/LICENSE))

