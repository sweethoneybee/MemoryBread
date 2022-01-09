//
//  Tutorial.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/22.
//

import Foundation

struct Tutorial {
    struct Info {
        var title: String
        var content: String
        var filterIndexes: [(Int, Int)]
    }
    
    var infos = [
        Info(title: "4. 엑셀 파일로 암기빵 만들기",
             content: "엑셀 파일로 파일당 한 번에 최대 500개의 암기빵을 만들 수 있습니다. 엑셀파일의 A열에 암기빵의 제목을, B열에 암기빵을 내용을 입력하고 저장하세요. 하나의 행은 한 개의 암기빵을 의미합니다. 엑셀 파일을 자신의 구글 드라이브에 업로드 하고, 앱 내에서 로그인하고, 다운로드 받으세요. 암기빵 목록에서 오른쪽 위의 네모난 버튼을 누르면 구글 드라이브에 로그인할 수 있습니다. 엑셀파일을 사용해 대량의 암기빵을 빠르고 쉽게 만들어보세요!",
             filterIndexes: []
            ),
        Info(title: "3. 암기빵 생성 및 제목, 내용 수정 방법",
             content: "암기빵 목록에서 오른쪽 아래의 '+' 버튼을 누르면 새로운 암기빵을 생성할 수 있습니다. 제목을 수정하고 싶다면 제목을 터치하여 수정할 수 있습니다. 내용을 수정하고 싶다면 오른쪽 위의 메모지 버튼을 터치하여 수정합니다. 내용이 수정되면 기존의 색필터 정보는 모두 사라지니 주의해주세요.",
             filterIndexes: [
                (0, 2),
                (1, 2),
                (2, 2),
                (3, 2),
                (4, 2),
                (5, 2),
                (6, 2),
                (7, 2),
                (8, 2),
                (9, 2),
                (10, 2),
                (11, 2),
                (12, 2),
                (13, 2),
                (14, 2),
                (15, 2),
             ]),
        Info(title: "2. 색필터 보기 및 편집 방법",
             content: "아래에 있는 동그라미들을 터치하면(이것을 '필터 동그라미'라고 부릅니다) 해당하는 색필터로 단어를 가립니다. 필터 동그라미 안의 숫자는 선택된 단어의 개수를 의미합니다. 오른쪽 위의 '편집' 버튼을 터치하면 단어에 입혀진 색필터를 편집할 수 있는 편집모드가 됩니다. 이때 색필터가 입혀진 단어를 터치하면 색필터가 제거됩니다. 단어에 필터를 입히고 싶을 땐 아래 필터 동그라미를 터치하고, 원하는 단어를 터치하거나 드래그합니다. 필터 동그라미가 선택되었을 땐 페이지를 위아래로 스크롤할 수 없습니다. 위아래로 스크롤하고 싶다면 필터 동그라미를 다시 터치해서 선택을 해제해주세요. 색필터 편집이 끝나면 오른쪽 위의 '완료' 버튼을 터치합니다.",
             filterIndexes: [
                (0, 2),
                (1, 2),
                (2, 2),
                (17, 3),
                (18, 3),
                (24, 3),
                (27, 3),
                (36, 3),
                (60, 4),
                (72, 4),
                (75, 4)
             ]
            ),
        Info(title: "1. 암기빵은 무엇인가요",
             content: "암기빵은 문장의 단어를 선택해서 가릴 수 있게 도와주는 앱입니다. 암기빵과 함께 긴 문장의 중간중간 단어를 가리며 스스로 잘 외웠는지 점검해보세요! 사용방법은 '2. 색필터 보기 및 편집 방법', '3. 새로운 암기빵 생성 및 제목, 내용 수정 방법'을 읽어주세요.",
             filterIndexes: []
            ),
    ]
}
