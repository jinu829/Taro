//import 'dart:math'; // 랜덤 뽑기를 위해 필요
import 'dart:typed_data'; // 이미지 데이터를 다루기 위해 필요
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // 앱 안의 이미지 파일을 읽기 위해 필요
import 'package:google_generative_ai/google_generative_ai.dart'; // Gemini AI와 통신하기 위해 필요
import 'package:flip_card/flip_card.dart'; // 카드 뒤집기 효과를 위해 필요

void main() {
  runApp(TarotApp());
}

// 앱의 시작점
class TarotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 앱 전체의 디자인 테마를 어둡고 신비롭게 설정합니다.
    return MaterialApp(
      title: 'AI 타로',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1A1A2E), // 짙은 남색 배경
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF16213E)),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFE94560), // 강조색 (버튼 등)
          secondary: Color(0xFF0F3460),
        ),
      ),
      home: FirstScreen(),
    );
  }
}

// 1. 첫 번째 화면 (운세 선택)
class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('신비한 AI 타로')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('어떤 운세를 점쳐볼까요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 40),
            // 4개의 운세 버튼 배치
            FortuneButton(fortuneType: '연애운', icon: Icons.favorite),
            FortuneButton(fortuneType: '금전운', icon: Icons.monetization_on),
            FortuneButton(fortuneType: '대인관계운', icon: Icons.people),
            FortuneButton(fortuneType: '한 해 운세', icon: Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}

// 운세 선택 버튼 디자인 위젯
class FortuneButton extends StatelessWidget {
  final String fortuneType;
  final IconData icon;
  FortuneButton({required this.fortuneType, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0F3460),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 60), // 버튼을 넓고 높게
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        icon: Icon(icon),
        label: Text(fortuneType, style: TextStyle(fontSize: 18)),
        onPressed: () {
          // 버튼 클릭 시 카드 뽑기 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CardScreen(selectedFortune: fortuneType)),
          );
        },
      ),
    );
  }
}

// 2. 두 번째 화면 (카드 78장 펼치고 3장 뽑기)
class CardScreen extends StatefulWidget {
  final String selectedFortune;
  CardScreen({required this.selectedFortune});

  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  List<int> shuffledDeck = []; // 미리 섞어둔 78장의 카드 덱
  List<int> pickedCards = [];  // 사용자가 뽑은 카드 번호를 담을 바구니

  @override
  void initState() {
    super.initState();
    // 화면이 처음 켜질 때, 0번부터 77번까지 카드를 생성하고 무작위로 마구 섞습니다.
    shuffledDeck = List.generate(78, (index) => index);
    shuffledDeck.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.selectedFortune} 뽑기 (${pickedCards.length}/3)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              pickedCards.length < 3 ? '직감을 믿고 카드를 선택해주세요.' : '3장을 모두 선택하셨습니다.',
              style: TextStyle(fontSize: 18),
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, 
                childAspectRatio: 0.6, 
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 78,
              itemBuilder: (context, index) {
                // 이 격자(자리)에 엎어져 있는 실제 타로 카드 번호
                int actualCardNumber = shuffledDeck[index];
                // 이미 뽑힌 카드인지 확인
                bool isPicked = pickedCards.contains(actualCardNumber);

                // 🎉 대망의 FlipCard 위젯 적용!
                return FlipCard(
                  key: ValueKey(actualCardNumber), // 카드가 섞이지 않게 이름표를 붙여줍니다.
                  // 아직 안 뽑혔고, 전체 뽑은 카드가 3장 미만일 때만 터치해서 뒤집을 수 있음
                  flipOnTouch: !isPicked && pickedCards.length < 3,
                  // 카드가 뒤집히는 속도 (밀리초 단위, 400 = 0.4초)
                  speed: 400,
                  
                  // 카드가 뒤집힐 때 실행되는 동작
                  onFlip: () {
                    if (!isPicked && pickedCards.length < 3) {
                      setState(() {
                        pickedCards.add(actualCardNumber);
                      });
                    }
                  },
                  
                  // [Front]: 화면에 처음 보여질 모습 (타로 카드 뒷면 무늬)
                  front: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset('assets/tarot_back.png', fit: BoxFit.cover),
                  ),
                  
                  // [Back]: 카드가 휙! 뒤집히고 나서 보여질 모습 (실제 뽑힌 타로 그림)
                  back: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 8, offset: Offset(0, 0))],
                      border: Border.all(color: Colors.amber, width: 2), // 뽑힌 카드는 금빛 테두리
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset('assets/cards/$actualCardNumber.png', fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          
          if (pickedCards.length == 3)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                icon: Icon(Icons.auto_awesome),
                label: Text('Gemini가 해석해주는 결과 보기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(
                        fortuneType: widget.selectedFortune,
                        pickedCards: pickedCards, // 뽑힌 얼굴 번호 3개를 그대로 넘겨줌
                      ),
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}

// 3. 세 번째 화면 (Gemini에게 이미지 보내고 해석 결과 받기)
class ResultScreen extends StatelessWidget {
  final String fortuneType;
  final List<int> pickedCards;

  ResultScreen({required this.fortuneType, required this.pickedCards});

  // Gemini API와 통신하는 핵심 함수
  Future<String> _getAIReadingWithImages() async {
    // ⚠️ TODO: 여기에 발급받은 실제 Gemini API 키를 입력하세요!
    const apiKey = 'YOUR_API_KEY_HERE'; 
    
    if (apiKey == 'YOUR_API_KEY_HERE') {
      await Future.delayed(Duration(seconds: 1));
      return 'API 키가 설정되지 않았습니다. 코드에서 apiKey 변수에 키를 입력해주세요.';
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    try {
      // 1. 뽑힌 3장의 카드 이미지를 앱 내부에서 읽어와서 바이트 데이터로 변환
      List<Uint8List> imageBytesList = [];
      for (int cardIndex in pickedCards) {
        final ByteData data = await rootBundle.load('assets/cards/$cardIndex.png');
        imageBytesList.add(data.buffer.asUint8List());
      }

      // 2. AI에게 보낼 텍스트 명령어 작성
      final textPrompt = TextPart('''
        너는 통찰력 있고 따뜻한 전문 타로 리더야.
        사용자는 지금 [$fortuneType]에 대해 궁금해하며 3장의 카드를 뽑았어.
        
        내가 함께 보낸 3장의 카드 이미지를 순서대로(과거-현재-미래) 자세히 보고,
        그림 속의 상징, 인물의 표정, 분위기를 사용자의 상황과 연결해서 해석해 줘.
        
        딱딱한 설명보다는, 내담자에게 직접 말하듯이 부드럽고 공감 가는 말투로 이야기해 줘.
        결과는 서론 없이 바로 해석 내용으로 시작해서 3문단 정도로 정리해 줘.
      ''');

      // 3. 텍스트와 이미지 3장을 하나의 메시지로 묶음
      final content = Content.multi([
        textPrompt,
        DataPart('image/png', imageBytesList[0]), // 과거 카드 이미지
        DataPart('image/png', imageBytesList[1]), // 현재 카드 이미지
        DataPart('image/png', imageBytesList[2]), // 미래 카드 이미지
      ]);

      // 4. Gemini에게 전송하고 응답을 기다림
      final response = await model.generateContent([content]);
      return response.text ?? '해석을 불러오지 못했습니다. 다시 시도해주세요.';

    } catch (e) {
      return '오류가 발생했습니다: $e\n\n이미지 파일이 assets 폴더에 제대로 있는지, pubspec.yaml에 등록되었는지 확인해주세요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$fortuneType 해석 결과')),
      // FutureBuilder: AI의 응답을 기다리는 동안 로딩 화면을 보여주는 도구
      body: FutureBuilder<String>(
        future: _getAIReadingWithImages(),
        builder: (context, snapshot) {
          // 1) 아직 데이터를 기다리는 중 (로딩)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE94560)),
                  SizedBox(height: 25),
                  Text('Gemini가 카드의 그림을 분석하고 있습니다...', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  SizedBox(height: 10),
                  Text('잠시만 기다려주세요.', style: TextStyle(fontSize: 14, color: Colors.white54)),
                ],
              ),
            );
          } 
          // 2) 에러 발생
          else if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('에러 발생: ${snapshot.error}', style: TextStyle(color: Colors.redAccent)),
            ));
          } 
          // 3) 데이터 도착 완료 (성공!)
          else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단에 뽑은 카드 3장을 작게 다시 보여줌
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: pickedCards.map((index) => 
                      Container(
                        width: 80, height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset('assets/cards/$index.png', fit: BoxFit.cover),
                      )
                    ).toList(),
                  ),
                  SizedBox(height: 30),
                  // AI의 해석 내용
                  Text(
                    snapshot.data ?? '',
                    style: TextStyle(fontSize: 16, height: 1.8, color: Colors.white.withOpacity(0.9)),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}