import 'package:flutter/material.dart';
import 'package:golbang/models/event.dart';

class UpcomingEvents extends StatelessWidget {
  final List<Event> events;

  const UpcomingEvents({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];

            // 첫 번째 참여자의 상태를 사용하여 테두리 색상 설정
            String? statusType = event.participants.isNotEmpty ? event.participants[0].statusType : '미정';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: _getBorderColor(statusType!),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(4),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.eventTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // if (event.isCompleted)
                        //   const Icon(
                        //     Icons.admin_panel_settings,
                        //     color: Colors.green,
                        //     size: 25,
                        //   ),
                      ],
                    ),
                    Text(
                      '${event.startDateTime.toLocal()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('장소: ${event.location}'),
                    Row(
                      children: [
                        const Text('참석 여부: '),
                        _buildStatusButton(statusType),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status) {
    Color color;
    switch (status) {
      case '참석':
        color = Colors.cyan;
        break;
      case '불참':
        color = Colors.red;
        break;
      case '미정':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(40, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Color _getBorderColor(String status) {
    switch (status) {
      case '참석':
        return Colors.cyan;
      case '불참':
        return Colors.red;
      case '미정':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
