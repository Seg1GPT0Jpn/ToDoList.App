// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const shikakuCurriculum = CurriculumNode(
  id: 'shikaku',
  name: '資格',
  level: CurriculumLevel.subject,
  gameName: '資格の塔',
  curriculumReference: '各資格試験の出題範囲（試験実施機関の公表資料）',
  source: '各資格試験の実施機関の公表資料',
  sourceUrl: 'https://www.retio.or.jp/exam/',
  children: [
    CurriculumNode(
      id: 'shikaku.takken',
      name: '宅建士',
      level: CurriculumLevel.course,
      gameName: '宅建の道',
      description: '宅地建物取引士試験（権利関係・宅建業法・法令上の制限・税その他）',
      curriculumReference: '宅地建物取引士資格試験の試験内容（宅建業法施行規則第8条）',
      source: '一般財団法人 不動産適正取引推進機構「宅建試験 試験の内容」',
      sourceUrl: 'https://www.retio.or.jp/exam/',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'shikaku.takken.kenri',
          name: '権利関係',
          level: CurriculumLevel.field,
          curriculumReference: '民法・借地借家法・区分所有法・不動産登記法',
          children: [
            CurriculumNode(
              id: 'shikaku.takken.kenri.ishi',
              name: '意思表示と制限行為能力',
              level: CurriculumLevel.unit,
              description: '制限行為能力者・心裡留保・虚偽表示・錯誤・詐欺・強迫',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.kenri.ishi.seigen',
                  name: '制限行為能力者',
                  level: CurriculumLevel.subUnit,
                  keywords: ['未成年者', '成年被後見人', '被保佐人', '被補助人'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.kenri.ishi.hyouji',
                  name: '意思表示',
                  level: CurriculumLevel.subUnit,
                  keywords: ['心裡留保', '虚偽表示', '錯誤', '詐欺', '強迫'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.kenri.dairi',
              name: '代理と時効',
              level: CurriculumLevel.unit,
              description: '代理・無権代理・表見代理・取得時効・消滅時効',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.kenri.dairi.dairi',
                  name: '代理',
                  level: CurriculumLevel.subUnit,
                  keywords: ['代理', '無権代理', '表見代理', '復代理'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.kenri.dairi.jikou',
                  name: '時効',
                  level: CurriculumLevel.subUnit,
                  keywords: ['時効', '取得時効', '消滅時効'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.kenri.bukken',
              name: '物権変動と抵当権',
              level: CurriculumLevel.unit,
              description: '対抗要件・抵当権・根抵当権',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.kenri.bukken.henndou',
                  name: '物権変動と登記',
                  level: CurriculumLevel.subUnit,
                  keywords: ['対抗', '登記', '二重譲渡'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.kenri.bukken.teitou',
                  name: '抵当権と根抵当権',
                  level: CurriculumLevel.subUnit,
                  keywords: ['抵当権', '根抵当権', '物上代位', '法定地上権'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.kenri.saiken',
              name: '債権と契約',
              level: CurriculumLevel.unit,
              description: '債務不履行・解除・手付・契約不適合責任・賃貸借',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.kenri.saiken.fuko',
                  name: '債務不履行と解除',
                  level: CurriculumLevel.subUnit,
                  keywords: ['債務不履行', '解除', '手付'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.kenri.saiken.futekigou',
                  name: '契約不適合責任',
                  level: CurriculumLevel.subUnit,
                  keywords: ['契約不適合', '追完', '代金減額'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.kenri.saiken.chintai',
                  name: '賃貸借',
                  level: CurriculumLevel.subUnit,
                  keywords: ['賃貸借', '敷金', '転貸'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.kenri.tokubetsu',
              name: '借地借家・登記・相続',
              level: CurriculumLevel.unit,
              description: '借地借家法・不動産登記法・相続',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.kenri.tokubetsu.shakuchi',
                  name: '借地借家法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['借地', '借家', '定期借地', '定期建物賃貸借'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.kenri.tokubetsu.touki',
                  name: '不動産登記法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['登記', '表題登記', '相続登記'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.kenri.tokubetsu.souzoku',
                  name: '相続',
                  level: CurriculumLevel.subUnit,
                  keywords: ['相続', '遺言', '遺留分', '相続放棄'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'shikaku.takken.gyouhou',
          name: '宅建業法',
          level: CurriculumLevel.field,
          curriculumReference: '宅地建物取引業法',
          children: [
            CurriculumNode(
              id: 'shikaku.takken.gyouhou.menkyo',
              name: '宅建業と免許',
              level: CurriculumLevel.unit,
              description: '宅建業の定義・免許・欠格事由',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.menkyo.teigi',
                  name: '宅建業の定義',
                  level: CurriculumLevel.subUnit,
                  keywords: ['宅地', '建物', '取引', '業'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.menkyo.menkyo',
                  name: '免許と欠格事由',
                  level: CurriculumLevel.subUnit,
                  keywords: ['免許', '欠格', '知事', '大臣'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.gyouhou.takkenshi',
              name: '宅建士と保証制度',
              level: CurriculumLevel.unit,
              description: '宅建士・営業保証金・保証協会',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.takkenshi.shi',
                  name: '宅地建物取引士',
                  level: CurriculumLevel.subUnit,
                  keywords: ['宅建士', '登録', '取引士証'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.takkenshi.hoshou',
                  name: '営業保証金と保証協会',
                  level: CurriculumLevel.subUnit,
                  keywords: ['営業保証金', '保証協会', '弁済業務保証金'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.gyouhou.juusetsu',
              name: '媒介・広告・重要事項説明',
              level: CurriculumLevel.unit,
              description: '媒介契約・広告規制・35条書面',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.juusetsu.baikai',
                  name: '媒介契約',
                  level: CurriculumLevel.subUnit,
                  keywords: ['媒介', '専任', '指定流通機構'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.juusetsu.koukoku',
                  name: '広告と取引態様',
                  level: CurriculumLevel.subUnit,
                  keywords: ['広告', '誇大', '取引態様'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.juusetsu.s35',
                  name: '重要事項説明',
                  level: CurriculumLevel.subUnit,
                  keywords: ['重要事項', '35条'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.gyouhou.keiyaku',
              name: '37条書面と8種制限',
              level: CurriculumLevel.unit,
              description: '37条書面・自ら売主制限・クーリング・オフ',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.keiyaku.s37',
                  name: '37条書面',
                  level: CurriculumLevel.subUnit,
                  keywords: ['37条'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.keiyaku.hachi',
                  name: '自ら売主の8種制限',
                  level: CurriculumLevel.subUnit,
                  keywords: ['手付', '損害賠償', '自ら売主', '手付金等'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.keiyaku.cooling',
                  name: 'クーリング・オフ',
                  level: CurriculumLevel.subUnit,
                  keywords: ['クーリング'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.gyouhou.houshu',
              name: '報酬と監督処分',
              level: CurriculumLevel.unit,
              description: '報酬額の制限・監督処分・罰則',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.houshu.houshu',
                  name: '報酬',
                  level: CurriculumLevel.subUnit,
                  keywords: ['報酬'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.gyouhou.houshu.kantoku',
                  name: '監督処分と罰則',
                  level: CurriculumLevel.subUnit,
                  keywords: ['指示', '業務停止', '免許取消'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'shikaku.takken.seigen',
          name: '法令上の制限',
          level: CurriculumLevel.field,
          curriculumReference: '都市計画法・建築基準法ほか',
          children: [
            CurriculumNode(
              id: 'shikaku.takken.seigen.toshi',
              name: '都市計画法',
              level: CurriculumLevel.unit,
              description: '都市計画区域・区域区分・用途地域・開発許可',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.seigen.toshi.keikaku',
                  name: '都市計画の内容',
                  level: CurriculumLevel.subUnit,
                  keywords: ['市街化', '用途地域', '都市計画区域'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.seigen.toshi.kaihatsu',
                  name: '開発許可',
                  level: CurriculumLevel.subUnit,
                  keywords: ['開発'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.seigen.kenchiku',
              name: '建築基準法',
              level: CurriculumLevel.unit,
              description: '用途制限・建蔽率・容積率・道路',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.seigen.kenchiku.youto',
                  name: '道路と用途制限',
                  level: CurriculumLevel.subUnit,
                  keywords: ['道路', '用途', '接道'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.seigen.kenchiku.menseki',
                  name: '建蔽率・容積率・高さ',
                  level: CurriculumLevel.subUnit,
                  keywords: ['建蔽率', '容積率', '日影', '高さ'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.seigen.sonota',
              name: 'その他の法令',
              level: CurriculumLevel.unit,
              description: '国土利用計画法・農地法・盛土規制法・土地区画整理法',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.seigen.sonota.kokudo',
                  name: '国土利用計画法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['国土', '事後届出'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.seigen.sonota.nouchi',
                  name: '農地法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['農地'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.seigen.sonota.morido',
                  name: '盛土規制法と区画整理',
                  level: CurriculumLevel.subUnit,
                  keywords: ['盛土', '宅地造成', '区画整理'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'shikaku.takken.zei',
          name: '税・その他',
          level: CurriculumLevel.field,
          curriculumReference: '税法・不動産の価格の評定・5問免除科目',
          children: [
            CurriculumNode(
              id: 'shikaku.takken.zei.zei',
              name: '不動産の税',
              level: CurriculumLevel.unit,
              description: '不動産取得税・固定資産税・登録免許税・印紙税・譲渡所得',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.zei.zei.chihou',
                  name: '地方税',
                  level: CurriculumLevel.subUnit,
                  keywords: ['不動産取得税', '固定資産税'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.zei.zei.kokuzei',
                  name: '国税',
                  level: CurriculumLevel.subUnit,
                  keywords: ['登録免許税', '印紙税', '所得税', '譲渡'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.zei.kakaku',
              name: '地価公示と鑑定評価',
              level: CurriculumLevel.unit,
              description: '地価公示法・不動産鑑定評価基準',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.zei.kakaku.kouji',
                  name: '地価公示',
                  level: CurriculumLevel.subUnit,
                  keywords: ['地価公示', '標準地'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.zei.kakaku.kantei',
                  name: '不動産鑑定評価',
                  level: CurriculumLevel.subUnit,
                  keywords: ['鑑定評価', '原価法', '取引事例', '収益還元'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'shikaku.takken.zei.menjo',
              name: '免除科目',
              level: CurriculumLevel.unit,
              description: '住宅金融支援機構・景品表示法・土地と建物',
              children: [
                CurriculumNode(
                  id: 'shikaku.takken.zei.menjo.kikou',
                  name: '住宅金融支援機構',
                  level: CurriculumLevel.subUnit,
                  keywords: ['機構', 'フラット'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.zei.menjo.keihyou',
                  name: '景品表示法と公正競争規約',
                  level: CurriculumLevel.subUnit,
                  keywords: ['表示', '景品', '徒歩'],
                ),
                CurriculumNode(
                  id: 'shikaku.takken.zei.menjo.tochi',
                  name: '土地と建物',
                  level: CurriculumLevel.subUnit,
                  keywords: ['土地', '建物', '木造', '鉄筋'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
