// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const kokkaCurriculum = CurriculumNode(
  id: 'kokka',
  name: '三大国家試験',
  level: CurriculumLevel.subject,
  gameName: '三大国家試験の世界',
  curriculumReference: '司法試験・医師国家試験・公認会計士試験の出題範囲（各実施機関の公表資料）',
  source: '法務省「司法試験」・厚生労働省「医師国家試験」・公認会計士・監査審査会「公認会計士試験」',
  sourceUrl: 'https://www.moj.go.jp/jinji/shihoushiken/',
  children: [
    CurriculumNode(
      id: 'kokka.shiho',
      name: '司法試験',
      level: CurriculumLevel.course,
      gameName: '司法試験の道',
      description: '司法試験の基礎（公法系・民事系・刑事系）',
      curriculumReference: '司法試験の試験科目',
      source: '法務省「司法試験」',
      sourceUrl: 'https://www.moj.go.jp/jinji/shihoushiken/',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'kokka.shiho.kouhou',
          name: '公法系',
          level: CurriculumLevel.field,
          curriculumReference: '憲法・行政法',
          children: [
            CurriculumNode(
              id: 'kokka.shiho.kouhou.jinken',
              name: '憲法：人権',
              level: CurriculumLevel.unit,
              description: '人権総論・精神的自由・経済的自由と社会権',
              children: [
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.jinken.souron',
                  name: '人権総論',
                  level: CurriculumLevel.subUnit,
                  keywords: ['人権', '平等', '私人間', '外国人'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.jinken.jiyu',
                  name: '精神的自由と人身の自由',
                  level: CurriculumLevel.subUnit,
                  keywords: ['思想', '表現', '信教', '学問', '被告人'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.jinken.keizai',
                  name: '経済的自由と社会権',
                  level: CurriculumLevel.subUnit,
                  keywords: ['職業', '財産権', '生存権', '勤労'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.shiho.kouhou.touchi',
              name: '憲法：統治',
              level: CurriculumLevel.unit,
              description: '国会・内閣・裁判所・地方自治・憲法改正',
              children: [
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.touchi.kokkai',
                  name: '国会',
                  level: CurriculumLevel.subUnit,
                  keywords: ['国会', '衆議院', '参議院'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.touchi.naikaku',
                  name: '内閣',
                  level: CurriculumLevel.subUnit,
                  keywords: ['内閣', '総理大臣', '国務大臣'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.touchi.shihou',
                  name: '裁判所',
                  level: CurriculumLevel.subUnit,
                  keywords: ['裁判所', '違憲審査', '国民審査'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.touchi.chiho',
                  name: '地方自治',
                  level: CurriculumLevel.subUnit,
                  keywords: ['地方自治', '条例'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.shiho.kouhou.gyosei',
              name: '行政法',
              level: CurriculumLevel.unit,
              description: '行政行為・行政手続・行政救済',
              children: [
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.gyosei.koui',
                  name: '行政行為と行政手続',
                  level: CurriculumLevel.subUnit,
                  keywords: ['行政行為', '聴聞', '行政指導'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.kouhou.gyosei.kyusai',
                  name: '行政救済',
                  level: CurriculumLevel.subUnit,
                  keywords: ['取消訴訟', '審査請求', '国家賠償'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.shiho.minji',
          name: '民事系',
          level: CurriculumLevel.field,
          curriculumReference: '民法・商法・民事訴訟法',
          children: [
            CurriculumNode(
              id: 'kokka.shiho.minji.minpo1',
              name: '民法：総則・物権',
              level: CurriculumLevel.unit,
              description: '権利能力・意思表示・物権変動・担保物権',
              children: [
                CurriculumNode(
                  id: 'kokka.shiho.minji.minpo1.souku',
                  name: '総則',
                  level: CurriculumLevel.subUnit,
                  keywords: ['権利能力', '成年', '公序良俗', '条件'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.minji.minpo1.bukken',
                  name: '物権',
                  level: CurriculumLevel.subUnit,
                  keywords: ['登記', '引渡し', '即時取得', '留置権', '抵当権'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.shiho.minji.minpo2',
              name: '民法：債権・家族',
              level: CurriculumLevel.unit,
              description: '契約・不法行為・婚姻・相続',
              children: [
                CurriculumNode(
                  id: 'kokka.shiho.minji.minpo2.saiken',
                  name: '債権',
                  level: CurriculumLevel.subUnit,
                  keywords: ['契約', '保証', '不法行為', '不当利得'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.minji.minpo2.kazoku',
                  name: '親族・相続',
                  level: CurriculumLevel.subUnit,
                  keywords: ['婚姻', '相続', '遺言', '遺留分'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.shiho.minji.shomin',
              name: '商法・民事訴訟法',
              level: CurriculumLevel.unit,
              description: '会社法の基礎・民事訴訟の原則',
              children: [
                CurriculumNode(
                  id: 'kokka.shiho.minji.shomin.kaisha',
                  name: '商法・会社法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['株式会社', '株主総会', '取締役会'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.minji.shomin.minso',
                  name: '民事訴訟法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['弁論主義', '処分権主義', '控訴', '既判力'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.shiho.keiji',
          name: '刑事系',
          level: CurriculumLevel.field,
          curriculumReference: '刑法・刑事訴訟法',
          children: [
            CurriculumNode(
              id: 'kokka.shiho.keiji.keiji',
              name: '刑法・刑事訴訟法',
              level: CurriculumLevel.unit,
              description: '犯罪の成立・個別の罪・捜査と公判',
              children: [
                CurriculumNode(
                  id: 'kokka.shiho.keiji.keiji.keiho',
                  name: '刑法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['罪刑法定', '正当防衛', '窃盗', '詐欺', '横領'],
                ),
                CurriculumNode(
                  id: 'kokka.shiho.keiji.keiji.keiso',
                  name: '刑事訴訟法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['令状', '勾留', '起訴', '一事不再理'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'kokka.ishi',
      name: '医師国家試験',
      level: CurriculumLevel.course,
      gameName: '医師国家試験の道',
      description: '医師国家試験の基礎（基礎医学・臨床医学・社会医学）',
      curriculumReference: '医師国家試験出題基準',
      source: '厚生労働省「医師国家試験出題基準」',
      sourceUrl: 'https://www.mhlw.go.jp/kouseiroudoushou/shikaku_shiken/ishi/',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'kokka.ishi.kiso',
          name: '基礎医学',
          level: CurriculumLevel.field,
          curriculumReference: '解剖学・生理学・生化学・薬理学・微生物学・免疫学・病理学',
          children: [
            CurriculumNode(
              id: 'kokka.ishi.kiso.kaibou',
              name: '解剖学・生理学',
              level: CurriculumLevel.unit,
              description: '人体の構造とはたらき',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.kiso.kaibou.kaibou',
                  name: '解剖学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['骨', '心臓', '肺', '腎臓', '神経'],
                ),
                CurriculumNode(
                  id: 'kokka.ishi.kiso.kaibou.seiri',
                  name: '生理学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['ホルモン', '体温', '血液'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.ishi.kiso.yakuri',
              name: '生化学・薬理学',
              level: CurriculumLevel.unit,
              description: '代謝・ビタミン・薬の効き方',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.kiso.yakuri.seika',
                  name: '生化学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['ATP', 'DNA', 'ビタミン'],
                ),
                CurriculumNode(
                  id: 'kokka.ishi.kiso.yakuri.yakuri',
                  name: '薬理学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['半減期', '抗菌薬', '拮抗薬'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.ishi.kiso.biseibutsu',
              name: '微生物学・免疫学',
              level: CurriculumLevel.unit,
              description: '病原体と生体防御',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.kiso.biseibutsu.meneki',
                  name: '免疫学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['抗体', 'IgE', 'IgG', 'ワクチン'],
                ),
                CurriculumNode(
                  id: 'kokka.ishi.kiso.biseibutsu.biseibutsu',
                  name: '微生物学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['細菌', 'ウイルス', '感染経路'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.ishi.kiso.byouri',
              name: '病理学',
              level: CurriculumLevel.unit,
              description: '腫瘍・循環障害・炎症・細胞の変化',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.kiso.byouri.byouri',
                  name: '病理学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['腫瘍', '血栓', '梗塞', '炎症'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.ishi.rinshou',
          name: '臨床医学',
          level: CurriculumLevel.field,
          curriculumReference: '内科・救急',
          children: [
            CurriculumNode(
              id: 'kokka.ishi.rinshou.junkan',
              name: '循環器・呼吸器',
              level: CurriculumLevel.unit,
              description: '高血圧・心筋梗塞・心不全・喘息・肺炎',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.rinshou.junkan.junkan',
                  name: '循環器',
                  level: CurriculumLevel.subUnit,
                  keywords: ['高血圧', '心筋梗塞', '心房細動', '心不全'],
                ),
                CurriculumNode(
                  id: 'kokka.ishi.rinshou.junkan.kokyuu',
                  name: '呼吸器',
                  level: CurriculumLevel.subUnit,
                  keywords: ['喘息', 'COPD', '気胸', '肺炎'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.ishi.rinshou.shouka',
              name: '消化器・腎臓・内分泌',
              level: CurriculumLevel.unit,
              description: '肝炎・膵炎・糖尿病・甲状腺・腎不全',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.rinshou.shouka.shouka',
                  name: '消化器',
                  level: CurriculumLevel.subUnit,
                  keywords: ['肝炎', '黄疸', '膵炎', '虫垂炎'],
                ),
                CurriculumNode(
                  id: 'kokka.ishi.rinshou.shouka.naibunpi',
                  name: '内分泌・代謝',
                  level: CurriculumLevel.subUnit,
                  keywords: ['糖尿病', '甲状腺', '副腎'],
                ),
                CurriculumNode(
                  id: 'kokka.ishi.rinshou.shouka.jinzou',
                  name: '腎臓・泌尿器',
                  level: CurriculumLevel.subUnit,
                  keywords: ['腎不全', '透析', '結石'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.ishi.rinshou.kyuukyuu',
              name: '救急',
              level: CurriculumLevel.unit,
              description: '心肺蘇生・意識障害・ショック・中毒',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.rinshou.kyuukyuu.kyuukyuu',
                  name: '救急',
                  level: CurriculumLevel.subUnit,
                  keywords: ['心肺蘇生', 'AED', 'ショック', 'トリアージ'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.ishi.shakai',
          name: '社会医学',
          level: CurriculumLevel.field,
          curriculumReference: '公衆衛生・医事法規',
          children: [
            CurriculumNode(
              id: 'kokka.ishi.shakai.koushu',
              name: '公衆衛生・医療制度',
              level: CurriculumLevel.unit,
              description: '医師法・感染症法・疫学・予防',
              children: [
                CurriculumNode(
                  id: 'kokka.ishi.shakai.koushu.seido',
                  name: '医療制度と医事法規',
                  level: CurriculumLevel.subUnit,
                  keywords: ['医師法', '臨床研修', '保険'],
                ),
                CurriculumNode(
                  id: 'kokka.ishi.shakai.koushu.koushu',
                  name: '公衆衛生と疫学',
                  level: CurriculumLevel.subUnit,
                  keywords: ['有病率', '罹患率', '感染症', '予防'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'kokka.kaikei',
      name: '公認会計士',
      level: CurriculumLevel.course,
      gameName: '公認会計士の道',
      description: '公認会計士試験の基礎（財務会計論・管理会計論・監査論・企業法・租税法）',
      curriculumReference: '公認会計士試験の試験科目',
      source: '公認会計士・監査審査会「公認会計士試験」',
      sourceUrl: 'https://www.fsa.go.jp/cpaaob/kouninkaikeishi-shiken/',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'kokka.kaikei.zaimu',
          name: '財務会計論',
          level: CurriculumLevel.field,
          curriculumReference: '簿記・財務諸表論',
          children: [
            CurriculumNode(
              id: 'kokka.kaikei.zaimu.boki',
              name: '簿記の基礎',
              level: CurriculumLevel.unit,
              description: '仕訳・決算整理',
              children: [
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.boki.shiwake',
                  name: '仕訳と財務諸表',
                  level: CurriculumLevel.subUnit,
                  keywords: ['借方', '貸方', '貸借対照表', '損益計算書'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.boki.kessan',
                  name: '決算整理',
                  level: CurriculumLevel.subUnit,
                  keywords: ['減価償却', '貸倒引当金', '経過勘定', '売上原価'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.kaikei.zaimu.kijun',
              name: '会計基準',
              level: CurriculumLevel.unit,
              description: '一般原則・資産と負債・税効果・キャッシュ・フロー',
              children: [
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.kijun.gensoku',
                  name: '一般原則と収益認識',
                  level: CurriculumLevel.subUnit,
                  keywords: ['継続性', '保守主義', '収益認識'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.kijun.shisan',
                  name: '資産の会計',
                  level: CurriculumLevel.subUnit,
                  keywords: ['棚卸資産', '減損', 'リース', '研究開発費'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.kijun.fusai',
                  name: '負債と純資産の会計',
                  level: CurriculumLevel.subUnit,
                  keywords: ['退職給付', '自己株式', '資産除去債務'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.kijun.zeikouka',
                  name: '税効果会計',
                  level: CurriculumLevel.subUnit,
                  keywords: ['繰延税金資産', '繰延税金負債'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.kijun.cf',
                  name: 'キャッシュ・フロー計算書',
                  level: CurriculumLevel.subUnit,
                  keywords: ['営業活動', '投資活動', '財務活動'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.kijun.kabushiki',
                  name: '1株当たり情報とストック・オプション',
                  level: CurriculumLevel.subUnit,
                  keywords: ['1株当たり', 'ストック・オプション'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'kokka.kaikei.zaimu.renketsu',
              name: '連結会計と企業結合',
              level: CurriculumLevel.unit,
              description: '連結の範囲・資本連結・持分法・企業結合',
              children: [
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.renketsu.renketsu',
                  name: '連結財務諸表',
                  level: CurriculumLevel.subUnit,
                  keywords: ['子会社', 'のれん', '非支配株主持分'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.renketsu.mochibun',
                  name: '持分法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['関連会社', '持分法'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.zaimu.renketsu.ketsugou',
                  name: '企業結合',
                  level: CurriculumLevel.subUnit,
                  keywords: ['パーチェス法', '取得'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.kaikei.kanri',
          name: '管理会計論',
          level: CurriculumLevel.field,
          curriculumReference: '原価計算・管理会計',
          children: [
            CurriculumNode(
              id: 'kokka.kaikei.kanri.genka',
              name: '原価計算と管理会計',
              level: CurriculumLevel.unit,
              description: '原価の分類・CVP分析・意思決定',
              children: [
                CurriculumNode(
                  id: 'kokka.kaikei.kanri.genka.genka',
                  name: '原価計算',
                  level: CurriculumLevel.subUnit,
                  keywords: ['直接費', '個別原価計算', '標準原価'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kanri.genka.cvp',
                  name: 'CVP分析と直接原価計算',
                  level: CurriculumLevel.subUnit,
                  keywords: ['変動費', '損益分岐点', '安全余裕率'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kanri.genka.ishikettei',
                  name: '意思決定会計',
                  level: CurriculumLevel.subUnit,
                  keywords: ['埋没原価', '機会原価', 'NPV'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.kaikei.kansa',
          name: '監査論',
          level: CurriculumLevel.field,
          curriculumReference: '監査基準',
          children: [
            CurriculumNode(
              id: 'kokka.kaikei.kansa.kansa',
              name: '監査論',
              level: CurriculumLevel.unit,
              description: '監査の目的・監査リスク・監査報告',
              children: [
                CurriculumNode(
                  id: 'kokka.kaikei.kansa.kansa.kihon',
                  name: '監査の基礎',
                  level: CurriculumLevel.subUnit,
                  keywords: ['独立性', '職業的懐疑心'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kansa.kansa.risk',
                  name: '監査リスクと監査手続',
                  level: CurriculumLevel.subUnit,
                  keywords: ['監査リスク', '発見リスク', '確認'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kansa.kansa.houkoku',
                  name: '監査報告',
                  level: CurriculumLevel.subUnit,
                  keywords: ['適正意見', '不適正意見', '意見不表明', 'KAM'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.kaikei.kigyou',
          name: '企業法',
          level: CurriculumLevel.field,
          curriculumReference: '会社法・金融商品取引法',
          children: [
            CurriculumNode(
              id: 'kokka.kaikei.kigyou.kaisha',
              name: '会社法・金融商品取引法',
              level: CurriculumLevel.unit,
              description: '設立・機関・計算・組織再編・開示',
              children: [
                CurriculumNode(
                  id: 'kokka.kaikei.kigyou.kaisha.setsuritsu',
                  name: '設立',
                  level: CurriculumLevel.subUnit,
                  keywords: ['発起設立', '募集設立'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kigyou.kaisha.kikan',
                  name: '機関',
                  level: CurriculumLevel.subUnit,
                  keywords: ['株主総会', '取締役', '監査役'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kigyou.kaisha.keisan',
                  name: '計算',
                  level: CurriculumLevel.subUnit,
                  keywords: ['剰余金', '配当'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kigyou.kaisha.saihen',
                  name: '組織再編',
                  level: CurriculumLevel.subUnit,
                  keywords: ['合併', '会社分割'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.kigyou.kaisha.kinsho',
                  name: '金融商品取引法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['有価証券報告書', '内部統制'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'kokka.kaikei.sozei',
          name: '租税法',
          level: CurriculumLevel.field,
          curriculumReference: '法人税法・所得税法・消費税法',
          children: [
            CurriculumNode(
              id: 'kokka.kaikei.sozei.sozei',
              name: '租税法',
              level: CurriculumLevel.unit,
              description: '法人税・所得税・消費税',
              children: [
                CurriculumNode(
                  id: 'kokka.kaikei.sozei.sozei.houjin',
                  name: '法人税',
                  level: CurriculumLevel.subUnit,
                  keywords: ['益金', '損金', '交際費'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.sozei.sozei.shotoku',
                  name: '所得税',
                  level: CurriculumLevel.subUnit,
                  keywords: ['所得', '累進', '給与所得控除'],
                ),
                CurriculumNode(
                  id: 'kokka.kaikei.sozei.sozei.shouhi',
                  name: '消費税',
                  level: CurriculumLevel.subUnit,
                  keywords: ['消費税', '軽減税率', 'インボイス'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
