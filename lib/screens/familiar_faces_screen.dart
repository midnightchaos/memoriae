import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/familiar_face.dart';
import '../services/familiar_face_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';
import '../widgets/animated_page_wrapper.dart';
import '../widgets/glass_card.dart';
import 'add_edit_face_screen.dart';

class FamiliarFacesScreen extends StatefulWidget {
  static const routeName = '/familiar-faces';

  const FamiliarFacesScreen({super.key});

  @override
  State<FamiliarFacesScreen> createState() => _FamiliarFacesScreenState();
}

class _FamiliarFacesScreenState extends State<FamiliarFacesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFaces();
  }

  Future<void> _loadFaces() async {
    final profileService = context.read<ProfileService>();
    if (profileService.profile != null) {
      await context.read<FamiliarFaceService>().loadFaces(
        profileService.profile!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final faceService = context.watch<FamiliarFaceService>();
    final faces = faceService.faces;
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return Scaffold(
      body: AnimatedPageWrapper(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  const Spacer(),
                  Text(
                    'Familiar Faces',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: pageStyle.sectionHeaderColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, size: 28),
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: _FacesSearchDelegate(
                          faceService,
                          _loadFaces,
                          context,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: faceService.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.lavender400,
                        ),
                      ),
                    )
                  : faces.isEmpty
                  ? _buildEmptyState()
                  : _buildFacesGrid(faces),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AddEditFaceScreen.routeName,
          );
          if (result == true) {
            await _loadFaces();
          }
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Person',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lavender500,
        elevation: 8,
      ),
    );
  }

  Widget _buildEmptyState() {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: pageStyle.iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: const Text('👥', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No familiar faces yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: pageStyle.sectionHeaderColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add photos of family and friends\nto help with recognition.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: pageStyle.subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFacesGrid(List<FamiliarFace> faces) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.8,
      ),
      itemCount: faces.length,
      itemBuilder: (context, index) {
        return StaggeredEntrance(
          index: index,
          child: _buildFaceCard(faces[index]),
        );
      },
    );
  }

  Widget _buildFaceCard(FamiliarFace face) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    final isBlack = pageStyle.pageColor == Colors.black;

    return GlassCard(
      onTap: () => _navigateToEdit(face),
      onLongPress: () => _showDeleteDialog(face),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: face.photoPath != null
                  ? Image.file(
                      File(face.photoPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: pageStyle.iconBackgroundColor,
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: pageStyle.iconAccentColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  face.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: pageStyle.sectionHeaderColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isBlack
                        ? Colors.white10
                        : AppColors.lavender500.withValues(alpha: 0.1),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Text(
                    face.relation,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isBlack ? Colors.white38 : AppColors.lavender500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(FamiliarFace face) async {
    final result = await Navigator.pushNamed(
      context,
      AddEditFaceScreen.routeName,
      arguments: face,
    );
    if (result == true) await _loadFaces();
  }

  void _showDeleteDialog(FamiliarFace face) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
        title: const Text('Delete Face'),
        content: Text('Remove ${face.name} from familiar faces?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final profileId = context.read<ProfileService>().profile?.id;
              if (profileId != null) {
                await context.read<FamiliarFaceService>().deleteFace(
                  face.id,
                  profileId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${face.name} removed')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacesSearchDelegate extends SearchDelegate {
  final FamiliarFaceService faceService;
  final VoidCallback onSearchComplete;
  final BuildContext parentContext;

  _FacesSearchDelegate(
    this.faceService,
    this.onSearchComplete,
    this.parentContext,
  );

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear_rounded),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final profileId = parentContext.read<ProfileService>().profile?.id ?? '';
    return FutureBuilder<List<FamiliarFace>>(
      future: faceService.searchFaces(profileId, query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No matches found'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) => _SearchResultCard(
            results[index],
            onSearchComplete,
            () => close(context, null),
          ),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final FamiliarFace face;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  const _SearchResultCard(this.face, this.onRefresh, this.onClose);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () {
        onClose();
        Navigator.pushNamed(
          context,
          AddEditFaceScreen.routeName,
          arguments: face,
        ).then((_) => onRefresh());
      },
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: face.photoPath != null
                  ? Image.file(
                      File(face.photoPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 48),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              face.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
