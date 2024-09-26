import 'package:flutter/material.dart';

class MemberAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  // onPressed를 외부에서 주입받기 위한 생성자
  MemberAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.add,
          color: Colors.green,
        ),
        label: Text(
          '멤버 추가',
          style: TextStyle(
            color: Colors.green,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.green,
          backgroundColor: Colors.white, // 버튼 텍스트 및 아이콘 색상
          side: BorderSide(color: Colors.green), // 테두리 색상
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // 둥근 모서리
          ),
        ),
      ),
    );
  }
}