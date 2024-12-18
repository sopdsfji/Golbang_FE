import 'package:flutter/material.dart';
import 'package:golbang/pages/community/community_main.dart';
import 'package:golbang/models/group.dart';

class GroupsSection extends StatefulWidget {
  final List<Group> groups;

  const GroupsSection({super.key, required this.groups});

  @override
  State<GroupsSection> createState() => _GroupsSectionState();
}

class _GroupsSectionState extends State<GroupsSection> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Dynamic UI settings
    double avatarRadius = screenWidth > 600 ? screenWidth * 0.1 : screenWidth * 0.08;
    double padding = screenWidth > 600 ? screenWidth * 0.04 : screenWidth * 0.02;
    double horizontalMargin = screenWidth > 600 ? screenWidth * 0.04 : screenWidth * 0.03;
    double textHeight = screenWidth > 600 ? screenWidth * 0.03 : screenWidth * 0.04;
    double spacing = textHeight / 2;
    double cardHeight = avatarRadius * 2 + textHeight + spacing + padding;

    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      controller: _scrollController, // Controller 연결
      child: SizedBox(
        height: cardHeight,
        child: ListView.builder(
          controller: _scrollController, // ScrollController 연결
          scrollDirection: Axis.horizontal,
          itemCount: widget.groups.length,
          itemBuilder: (context, index) {
            final group = widget.groups[index];
            return Padding(
              padding: EdgeInsets.only(right: padding),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityMain(
                        communityID: group.id,
                        communityName: group.name,
                        communityImage: group.image!,
                        adminNames: group.getAdminNames(),
                        isAdmin: group.isAdmin,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 0.5,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        width: avatarRadius * 2,
                        height: avatarRadius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: group.image != null && group.image!.contains('http')
                              ? DecorationImage(
                            image: NetworkImage(group.image!),
                            fit: BoxFit.fill,
                          )
                              : group.image != null
                              ? DecorationImage(
                            image: AssetImage(group.image!),
                            fit: BoxFit.fill,
                          )
                              : null,
                        ),
                        child: group.image == null
                            ? Center(
                          child: Text(
                            group.name.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                    SizedBox(height: spacing),
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: textHeight,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
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
}
