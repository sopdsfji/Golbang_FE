import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:golbang/pages/event/event_result.dart';
import '../../models/event.dart';
import '../../models/participant.dart';
import '../../provider/event/event_state_notifier_provider.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';
import '../game/score_card_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_update1.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;

  EventDetailPage({required this.event});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  List<bool> _isExpandedList = [false, false, false, false];
  LatLng? _selectedLocation;
  int? _myGroup;

  @override
  void initState() {
    super.initState();
    _selectedLocation = _parseLocation(widget.event.location);
    _myGroup = widget.event.memberGroup; // initState에서 초기화
  }

  LatLng? _parseLocation(String? location) {
    if (location == null) {
      return null;
    }

    try {
      if (location.startsWith('LatLng')) {
        final coords = location
            .substring(7, location.length - 1)
            .split(',')
            .map((e) => double.parse(e.trim()))
            .toList();
        return LatLng(coords[0], coords[1]);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  _editEvent();
                  break;
                case 'delete':
                  _deleteEvent();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('수정'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/golf_icon.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.eventTitle,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.event.startDateTime.toLocal().toIso8601String().split('T').first} • ${widget.event.endDateTime.hour}:${widget.event.startDateTime.minute.toString().padLeft(2, '0')} ~ ${widget.event.endDateTime.add(Duration(hours: 2)).hour}:${widget.event.startDateTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '장소: ${widget.event.site}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '게임모드: ${widget.event.gameMode}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '참여 인원: ${widget.event.participants.length}명',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '나의 조: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$_myGroup',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ExpansionPanelList(
                elevation: 1,
                expandedHeaderPadding: EdgeInsets.all(0),
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isExpandedList[index] = !_isExpandedList[index];
                  });
                },
                children: [
                  _buildParticipantPanel('참석 및 회식', widget.event.participants, 'PARTY', Color(0xFF4D08BD).withOpacity(0.3), 0),
                  _buildParticipantPanel('참석', widget.event.participants, 'ACCEPT', Color(0xFF08BDBD).withOpacity(0.3), 1),
                  _buildParticipantPanel('거절', widget.event.participants, 'DENY', Color(0xFFF21B3F).withOpacity(0.3), 2),
                  _buildParticipantPanel('대기', widget.event.participants, 'PENDING', Color(0xFF7E7E7E).withOpacity(0.3), 3),
                ],
              ),

              if (_selectedLocation != null) ...[
                SizedBox(height: 16),
                Text(
                  "골프장 위치",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 14.0,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId('selected-location'),
                        position: _selectedLocation!,
                      ),
                    },
                  ),
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "코스 정보",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    widget.event.golfClub != null
                        ? Column(
                      children: widget.event.golfClub!.courses.map((course) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.golf_course, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      course.courseName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "홀 수: ${course.holes}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      "코스 Par: ${course.par}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Divider(),
                                SizedBox(height: 10),
                                Text("홀 Par 정보", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(course.holes, (index) {
                                      final holeNumber = index + 1;
                                      final par = course.holePars[index];
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                          border: Border.all(color: Colors.grey[300]!, width: 1),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CustomPaint(
                                            painter: DiagonalTextPainter(holeNumber: holeNumber, par: par),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        : Text(
                      "코스 정보가 없습니다.",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBottomButtons(),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final DateTime currentDate = DateTime.now();
    final DateTime eventDate = widget.event.endDateTime;

    if (currentDate.isBefore(eventDate)) {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScoreCardPage(event: widget.event),
            ),
          );
        },
        child: Text('게임 시작'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventResultPage(eventId: widget.event.eventId),
            ),
          );
        },
        child: Text('결과 조회'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }
  }

  ExpansionPanel _buildParticipantPanel(String title, List<Participant> participants, String statusType, Color backgroundColor, int index) {
    final filteredParticipants = participants.where((p) => p.statusType == statusType).toList();
    final count = filteredParticipants.length;

    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(10),
          child: Text(
            '$title ($count):',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      },
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredParticipants.map((participant) {
            final member = participant.member;
            final isSameGroup = participant.groupType == _myGroup;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundImage: member?.profileImage != null
                        ? NetworkImage(member!.profileImage!)
                        : AssetImage('assets/images/user_default.png') as ImageProvider,
                  ),
                  SizedBox(width: 10),
                  Container(
                    decoration: isSameGroup
                        ? BoxDecoration(
                      color: Colors.yellow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    )
                        : null,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      member != null ? member.name : 'Unknown',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      isExpanded: _isExpandedList[index],
      canTapOnHeader: true,
    );
  }

  void _editEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventsUpdate1(event: widget.event),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _deleteEvent() async {
    final storage = ref.watch(secureStorageProvider);
    final success = await ref.read(eventStateNotifierProvider.notifier).deleteEvent(widget.event.eventId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('성공적으로 삭제되었습니다')),
      );
      Navigator.of(context).pop(true);
    } else if(success == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('관리자가 아닙니다. 관리자만 삭제할 수 있습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 삭제에 실패했습니다.')),
      );
    }
  }
}

// 대각선 구분선 및 텍스트 표시를 위한 CustomPainter
class DiagonalTextPainter extends CustomPainter {
  final int holeNumber;
  final int par;

  DiagonalTextPainter({required this.holeNumber, required this.par});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    final textStyle = TextStyle(color: Colors.black, fontSize: 12);
    final holeTextSpan = TextSpan(text: "$holeNumber홀", style: textStyle);
    final parTextSpan = TextSpan(text: "$par", style: textStyle);

    final holePainter = TextPainter(
      text: holeTextSpan,
      textDirection: TextDirection.ltr,
    );
    final parPainter = TextPainter(
      text: parTextSpan,
      textDirection: TextDirection.ltr,
    );

    holePainter.layout();
    parPainter.layout();

    holePainter.paint(canvas, Offset(5, 5));
    parPainter.paint(canvas, Offset(size.width - parPainter.width - 5, size.height - parPainter.height - 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
