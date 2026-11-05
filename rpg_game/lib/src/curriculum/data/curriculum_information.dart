// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const informationCurriculum = CurriculumNode(
  id: 'information',
  name: '情報',
  level: CurriculumLevel.subject,
  gameName: '情報の国',
  curriculumReference: '高等学校学習指導要領（平成30年告示）第2章第10節 情報',
  source: '文部科学省 高等学校学習指導要領（平成30年告示）',
  sourceUrl: 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm',
  children: [
    CurriculumNode(
      id: 'information.info',
      name: '情報',
      level: CurriculumLevel.course,
      gameName: '情報の道',
      description: '情報社会・情報デザイン・コンピュータ・プログラミング・ネットワーク・データ活用',
      curriculumReference: '情報Ⅰ・情報Ⅱ',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'information.info.society',
          name: '情報社会と問題解決',
          level: CurriculumLevel.field,
          curriculumReference: '情報Ⅰ 内容(1) 情報社会の問題解決',
          children: [
            CurriculumNode(
              id: 'information.info.society.nature',
              name: '情報社会と情報の特性',
              level: CurriculumLevel.unit,
              description: '情報の特性・メディア・情報社会の変化',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.society.nature.nature',
                  name: '情報の特性（残存性・複製性・伝播性）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['残存性', '複製', '伝播', '特性'],
                ),
                CurriculumNode(
                  id: 'information.info.society.nature.media',
                  name: 'メディアとメディアリテラシー',
                  level: CurriculumLevel.subUnit,
                  keywords: ['メディア', 'リテラシー', '情報の信頼性'],
                ),
                CurriculumNode(
                  id: 'information.info.society.nature.society',
                  name: '情報技術と社会の変化（AI・IoT・Society5.0）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['AI', 'IoT', '人工知能', 'Society', 'ビッグデータ', '情報社会'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.society.moral',
              name: '情報モラルと知的財産権',
              level: CurriculumLevel.unit,
              description: '法・権利・個人情報・情報モラル',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.society.moral.ip',
                  name: '知的財産権（著作権・産業財産権）',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    '著作権',
                    '知的財産',
                    '産業財産',
                    '特許',
                    '商標',
                    'クリエイティブ・コモンズ',
                    '引用'
                  ],
                ),
                CurriculumNode(
                  id: 'information.info.society.moral.privacy',
                  name: '個人情報とプライバシー',
                  level: CurriculumLevel.subUnit,
                  keywords: ['個人情報', 'プライバシー', '肖像権'],
                ),
                CurriculumNode(
                  id: 'information.info.society.moral.moral',
                  name: '情報モラルとネット上のトラブル',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    '情報モラル',
                    'SNS',
                    '炎上',
                    'ネットいじめ',
                    'フィルタリング',
                    'デジタルタトゥー'
                  ],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.society.security',
              name: '情報セキュリティ',
              level: CurriculumLevel.unit,
              description: '脅威と対策・認証',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.society.security.threat',
                  name: '脅威（マルウェア・フィッシング・ソーシャルエンジニアリング）',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    'マルウェア',
                    'ウイルス',
                    'フィッシング',
                    '不正アクセス',
                    'ランサム',
                    'ソーシャルエンジニアリング',
                    '心理的なすき'
                  ],
                ),
                CurriculumNode(
                  id: 'information.info.society.security.measure',
                  name: '対策（認証・パスワード・アップデート）',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    'パスワード',
                    '認証',
                    '二要素',
                    '多要素',
                    'ファイアウォール',
                    'アップデート',
                    'バックアップ'
                  ],
                ),
                CurriculumNode(
                  id: 'information.info.society.security.law',
                  name: '情報セキュリティと法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['不正アクセス禁止法', '法律'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.society.problem',
              name: '問題解決とモデル化',
              level: CurriculumLevel.unit,
              description: '問題解決の手順・モデル化・シミュレーション',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.society.problem.process',
                  name: '問題解決の手順',
                  level: CurriculumLevel.subUnit,
                  keywords: ['問題解決', 'PDCA', 'ブレーンストーミング', 'KJ法'],
                ),
                CurriculumNode(
                  id: 'information.info.society.problem.model',
                  name: 'モデル化とシミュレーション',
                  level: CurriculumLevel.subUnit,
                  keywords: ['モデル化', 'シミュレーション', 'モデル', '待ち行列', '乱数'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'information.info.design',
          name: '情報デザイン',
          level: CurriculumLevel.field,
          curriculumReference: '情報Ⅰ 内容(2) コミュニケーションと情報デザイン',
          children: [
            CurriculumNode(
              id: 'information.info.design.communication',
              name: 'コミュニケーションとメディア',
              level: CurriculumLevel.unit,
              description: 'コミュニケーションの形態・メディアの特性',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.design.communication.form',
                  name: 'コミュニケーションの形態',
                  level: CurriculumLevel.subUnit,
                  keywords: ['同期', '非同期', '1対1', '1対多', 'コミュニケーション'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.design.design',
              name: '情報デザイン',
              level: CurriculumLevel.unit,
              description: '抽象化・可視化・構造化・UI・ユニバーサルデザイン',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.design.design.principle',
                  name: 'デザインの原則（抽象化・可視化・構造化）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['抽象化', '可視化', '構造化', 'ピクトグラム', '情報デザイン'],
                ),
                CurriculumNode(
                  id: 'information.info.design.design.ui',
                  name: 'ユーザインタフェースとユニバーサルデザイン',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    'UI',
                    'ユーザインタフェース',
                    'ユニバーサル',
                    'アクセシビリティ',
                    'ユーザビリティ'
                  ],
                ),
                CurriculumNode(
                  id: 'information.info.design.design.layout',
                  name: '配色・レイアウト・Webページ',
                  level: CurriculumLevel.subUnit,
                  keywords: ['配色', 'レイアウト', '色', 'コントラスト', 'HTML', 'Web'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'information.info.computer',
          name: 'コンピュータと情報処理',
          level: CurriculumLevel.field,
          curriculumReference: '情報Ⅰ 内容(3) コンピュータとプログラミング',
          children: [
            CurriculumNode(
              id: 'information.info.computer.digital',
              name: 'デジタル化と2進数',
              level: CurriculumLevel.unit,
              description: '2進数・16進数・情報量・誤差',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.computer.digital.binary',
                  name: '2進数・16進数と基数変換',
                  level: CurriculumLevel.subUnit,
                  keywords: ['2進', '16進', '基数', 'ビット', 'バイト'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.digital.calc',
                  name: '2進数の計算と補数',
                  level: CurriculumLevel.subUnit,
                  keywords: ['補数', '加算', '桁あふれ', '負の数'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.digital.amount',
                  name: '情報量の単位',
                  level: CurriculumLevel.subUnit,
                  keywords: ['情報量', 'KB', 'MB', 'ビット数', '通り'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.computer.media',
              name: '文字・画像・音声のデジタル化',
              level: CurriculumLevel.unit,
              description: '文字コード・画像・音声・圧縮',
              grade: '1',
              prerequisites: ['information.info.computer.digital'],
              children: [
                CurriculumNode(
                  id: 'information.info.computer.media.text',
                  name: '文字のデジタル化（文字コード）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['文字コード', 'ASCII', 'Unicode', 'UTF'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.media.image',
                  name: '画像のデジタル化（画素・解像度・色）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['画素', '解像度', 'RGB', '階調', 'ベクタ', 'ラスタ'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.media.sound',
                  name: '音のデジタル化（標本化・量子化）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['標本化', '量子化', '符号化', 'サンプリング', '周波数'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.media.compress',
                  name: 'データの圧縮',
                  level: CurriculumLevel.subUnit,
                  keywords: ['圧縮', '可逆', '非可逆', 'ランレングス', 'ハフマン'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.computer.hardware',
              name: 'コンピュータの仕組み',
              level: CurriculumLevel.unit,
              description: 'ハードウェア・ソフトウェア・CPUの動作',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.computer.hardware.components',
                  name: 'コンピュータの構成要素',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    'CPU',
                    'メモリ',
                    '主記憶',
                    '補助記憶',
                    '入力装置',
                    '出力装置',
                    '五大装置'
                  ],
                ),
                CurriculumNode(
                  id: 'information.info.computer.hardware.cpu',
                  name: 'CPUの動作と命令',
                  level: CurriculumLevel.subUnit,
                  keywords: ['クロック', '命令', 'レジスタ', 'プログラムカウンタ', '機械語'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.hardware.software',
                  name: 'OSとソフトウェア',
                  level: CurriculumLevel.subUnit,
                  keywords: ['OS', 'ソフトウェア', 'アプリケーション'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.computer.system',
              name: '情報システム（情報Ⅱ）',
              level: CurriculumLevel.unit,
              description: '信頼性・稼働率・クラウド・情報システムの設計',
              grade: '2',
              children: [
                CurriculumNode(
                  id: 'information.info.computer.system.reliability',
                  name: '信頼性と稼働率（RAID・冗長化）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['稼働率', 'RAID', '冗長', '信頼性', 'フォールトトレラント', 'MTBF'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.system.cloud',
                  name: 'クラウドとWebサービス',
                  level: CurriculumLevel.subUnit,
                  keywords: ['クラウド', 'SaaS', 'IaaS', 'PaaS', 'サーバ'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.system.develop',
                  name: 'システム開発とテスト',
                  level: CurriculumLevel.subUnit,
                  keywords: ['ウォーターフォール', 'アジャイル', 'テスト', '要件'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.computer.logic',
              name: '論理回路',
              level: CurriculumLevel.unit,
              description: 'AND・OR・NOT・半加算器',
              grade: '1',
              prerequisites: ['information.info.computer.digital'],
              children: [
                CurriculumNode(
                  id: 'information.info.computer.logic.gate',
                  name: '論理演算と論理回路',
                  level: CurriculumLevel.subUnit,
                  keywords: ['AND', 'OR', 'NOT', 'XOR', '論理回路', '真理値表'],
                ),
                CurriculumNode(
                  id: 'information.info.computer.logic.adder',
                  name: '加算回路',
                  level: CurriculumLevel.subUnit,
                  keywords: ['半加算', '全加算'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'information.info.programming',
          name: 'アルゴリズムとプログラミング',
          level: CurriculumLevel.field,
          curriculumReference: '情報Ⅰ 内容(3) コンピュータとプログラミング',
          children: [
            CurriculumNode(
              id: 'information.info.programming.algorithm',
              name: 'アルゴリズム',
              level: CurriculumLevel.unit,
              description: '順次・分岐・反復・フローチャート',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.programming.algorithm.basic',
                  name: 'アルゴリズムの基本構造',
                  level: CurriculumLevel.subUnit,
                  keywords: ['順次', '分岐', '反復', 'フローチャート', 'アルゴリズム'],
                ),
                CurriculumNode(
                  id: 'information.info.programming.algorithm.search',
                  name: '探索（線形探索・二分探索）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['線形探索', '二分探索', '探索'],
                ),
                CurriculumNode(
                  id: 'information.info.programming.algorithm.sort',
                  name: '整列（ソート）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['ソート', '整列', 'バブル', '選択ソート', '挿入ソート', 'クイック'],
                ),
                CurriculumNode(
                  id: 'information.info.programming.algorithm.complexity',
                  name: '計算量と効率',
                  level: CurriculumLevel.subUnit,
                  keywords: ['計算量', '効率', '最大何回'],
                ),
                CurriculumNode(
                  id: 'information.info.programming.algorithm.structure',
                  name: 'データ構造（スタック・キュー・木）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['スタック', 'キュー', 'LIFO', 'FIFO', 'データ構造', '木構造'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.programming.program',
              name: 'プログラミング（DNCL・Python）',
              level: CurriculumLevel.unit,
              description: '変数・配列・関数・トレース',
              grade: '1',
              prerequisites: ['information.info.programming.algorithm'],
              children: [
                CurriculumNode(
                  id: 'information.info.programming.program.variable',
                  name: '変数と配列',
                  level: CurriculumLevel.subUnit,
                  keywords: ['変数', '配列', '代入', 'リスト'],
                ),
                CurriculumNode(
                  id: 'information.info.programming.program.control',
                  name: '条件分岐と繰り返し',
                  level: CurriculumLevel.subUnit,
                  keywords: ['もし', '繰り返', 'ループ', '条件式', '条件分岐'],
                ),
                CurriculumNode(
                  id: 'information.info.programming.program.function',
                  name: '関数と手続き',
                  level: CurriculumLevel.subUnit,
                  keywords: ['関数', '引数', '戻り値'],
                ),
                CurriculumNode(
                  id: 'information.info.programming.program.trace',
                  name: 'プログラムの読み取り（トレース）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['表示される', '実行結果', 'トレース', '出力', '実行後'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'information.info.network',
          name: '情報通信ネットワーク',
          level: CurriculumLevel.field,
          curriculumReference: '情報Ⅰ 内容(4) 情報通信ネットワークとデータの活用',
          children: [
            CurriculumNode(
              id: 'information.info.network.basic',
              name: 'ネットワークの基本',
              level: CurriculumLevel.unit,
              description: 'LAN・WAN・インターネットのしくみ',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.network.basic.structure',
                  name: 'LANとインターネットの構成',
                  level: CurriculumLevel.subUnit,
                  keywords: ['LAN', 'WAN', 'ルータ', 'スイッチ', 'インターネット'],
                ),
                CurriculumNode(
                  id: 'information.info.network.basic.address',
                  name: 'IPアドレス・サブネット・DNS',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    'IPアドレス',
                    'ドメイン',
                    'DNS',
                    'サブネット',
                    'ネットマスク',
                    'IPv4',
                    'IPv6',
                    'MACアドレス',
                    'DHCP'
                  ],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.network.protocol',
              name: 'プロトコルとWeb',
              level: CurriculumLevel.unit,
              description: 'TCP/IP・パケット・Web・メール',
              grade: '1',
              prerequisites: ['information.info.network.basic'],
              children: [
                CurriculumNode(
                  id: 'information.info.network.protocol.tcpip',
                  name: 'TCP/IPとパケット通信',
                  level: CurriculumLevel.subUnit,
                  keywords: ['TCP', 'IP', 'パケット', 'プロトコル', '階層'],
                ),
                CurriculumNode(
                  id: 'information.info.network.protocol.web',
                  name: 'Webとメールのしくみ',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    'HTTP',
                    'URL',
                    'Web',
                    'メール',
                    'SMTP',
                    'POP',
                    'IMAP'
                  ],
                ),
                CurriculumNode(
                  id: 'information.info.network.protocol.error',
                  name: '誤り検出（パリティ・チェックサム）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['パリティ', '誤り検出', 'チェックサム'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.network.crypto',
              name: '暗号とネットワークセキュリティ',
              level: CurriculumLevel.unit,
              description: '暗号方式・デジタル署名・SSL/TLS',
              grade: '1',
              prerequisites: ['information.info.network.protocol'],
              children: [
                CurriculumNode(
                  id: 'information.info.network.crypto.cipher',
                  name: '共通鍵暗号と公開鍵暗号',
                  level: CurriculumLevel.subUnit,
                  keywords: ['共通鍵', '公開鍵', '暗号', '秘密鍵', 'シーザー'],
                ),
                CurriculumNode(
                  id: 'information.info.network.crypto.signature',
                  name: 'ハッシュ・デジタル署名と認証局',
                  level: CurriculumLevel.subUnit,
                  keywords: ['デジタル署名', '認証局', '電子証明書', 'ハッシュ'],
                ),
                CurriculumNode(
                  id: 'information.info.network.crypto.tls',
                  name: 'HTTPSとVPN',
                  level: CurriculumLevel.subUnit,
                  keywords: ['HTTPS', 'SSL', 'TLS', 'VPN'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'information.info.data',
          name: 'データの活用',
          level: CurriculumLevel.field,
          curriculumReference: '情報Ⅰ 内容(4)・情報Ⅱ',
          children: [
            CurriculumNode(
              id: 'information.info.data.manage',
              name: 'データの整理と尺度',
              level: CurriculumLevel.unit,
              description: 'データの種類・尺度・データベース',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.data.manage.scale',
                  name: 'データの尺度（名義・順序・間隔・比例）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['名義尺度', '順序尺度', '間隔尺度', '比例尺度', '質的', '量的'],
                ),
                CurriculumNode(
                  id: 'information.info.data.manage.database',
                  name: 'データベースとデータの管理',
                  level: CurriculumLevel.subUnit,
                  keywords: ['データベース', '表', 'レコード', '主キー', 'SQL', 'リレーショナル'],
                ),
                CurriculumNode(
                  id: 'information.info.data.manage.open',
                  name: 'オープンデータとデータの収集',
                  level: CurriculumLevel.subUnit,
                  keywords: ['オープンデータ', '収集', 'アンケート'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'information.info.data.analysis',
              name: '統計とデータ分析',
              level: CurriculumLevel.unit,
              description: '代表値・散らばり・相関・回帰・可視化',
              grade: '1',
              children: [
                CurriculumNode(
                  id: 'information.info.data.analysis.stat',
                  name: '代表値と散らばり',
                  level: CurriculumLevel.subUnit,
                  keywords: ['平均', '中央値', '最頻値', '分散', '標準偏差', '四分位'],
                ),
                CurriculumNode(
                  id: 'information.info.data.analysis.correlation',
                  name: '相関と回帰',
                  level: CurriculumLevel.subUnit,
                  keywords: ['相関', '散布図', '回帰', '相関係数'],
                ),
                CurriculumNode(
                  id: 'information.info.data.analysis.visualize',
                  name: 'データの可視化と解釈',
                  level: CurriculumLevel.subUnit,
                  keywords: ['グラフ', 'ヒストグラム', '箱ひげ', '可視化'],
                ),
                CurriculumNode(
                  id: 'information.info.data.analysis.ml',
                  name: '機械学習とデータサイエンス（情報Ⅱ）',
                  level: CurriculumLevel.subUnit,
                  keywords: [
                    '機械学習',
                    'データサイエンス',
                    '学習データ',
                    'クラスタ',
                    '正解ラベル',
                    '教師あり',
                    '教師なし',
                    '正解率'
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
