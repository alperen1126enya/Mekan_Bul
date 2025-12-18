import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/yorum.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mekan_provider.dart';
import '../services/yorum_service.dart';
import '../utils/constants.dart';
import '../widgets/comment_box.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/menu_widget.dart';
import '../widgets/mini_map_widget.dart';
import '../widgets/page_wrapper.dart';
import '../widgets/photo_gallery_widget.dart';
import '../widgets/rating_stars.dart';

class MekanDetailScreen extends StatefulWidget {
  const MekanDetailScreen({super.key});

  @override
  State<MekanDetailScreen> createState() => _MekanDetailScreenState();
}

class _MekanDetailScreenState extends State<MekanDetailScreen> {
  final YorumService _yorumService = YorumService();
  List<Yorum> _yorumlar = [];
  bool _isLoadingYorumlar = true;
  bool _isSubmittingYorum = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadYorumlar());
  }

  Future<void> _loadYorumlar() async {
    final mekanProvider = context.read<MekanProvider>();
    final mekanId = mekanProvider.selectedMekan?.id;
    if (mekanId == null) return;

    setState(() => _isLoadingYorumlar = true);
    try {
      _yorumlar = await _yorumService.getComments(mekanId);
    } catch (e) {
      // Handle error silently
    }
    if (mounted) setState(() => _isLoadingYorumlar = false);
  }

  Future<void> _addYorum(int rating, String comment) async {
    final authProvider = context.read<AuthProvider>();
    final mekanProvider = context.read<MekanProvider>();

    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmittingYorum = true);
    try {
      await _yorumService.addComment(
        userId: authProvider.currentUser!.id!,
        mekanId: mekanProvider.selectedMekan!.id!,
        rating: rating,
        comment: comment,
      );
      await _loadYorumlar();
      await mekanProvider.refreshMekan(mekanProvider.selectedMekan!.id!, userId: authProvider.currentUser?.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorumunuz eklendi!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isSubmittingYorum = false);
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mekanProvider = context.watch<MekanProvider>();
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final mekan = mekanProvider.selectedMekan;

    if (mekan == null || mekanProvider.isLoading) {
      return const PageWrapper(
        showBackButton: true,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return PageWrapper(
      showBackButton: true,
      extendBodyBehindAppBar: true,
      actions: [
        if (authProvider.isLoggedIn)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mekan.isFavorite ? AppColors.accent.withValues(alpha: 0.2) : AppColors.surfaceLight.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                mekan.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: mekan.isFavorite ? AppColors.accent : null,
                size: 20,
              ),
            ),
            onPressed: () async {
              await favoritesProvider.toggleFavorite(authProvider.currentUser!.id!, mekan);
              mekanProvider.refreshMekan(mekan.id!, userId: authProvider.currentUser?.id);
            },
          ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(mekan),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Gallery
                  PhotoGalleryWidget(
                    mekanId: mekan.id!,
                    mekanName: mekan.name,
                  ),
                  const SizedBox(height: 24),
                  // Menu
                  MenuWidget(
                    mekanId: mekan.id!,
                    mekanName: mekan.name,
                  ),
                  const SizedBox(height: 24),
                  // Mini Map
                  MiniMapWidget(
                    latitude: mekan.latitude,
                    longitude: mekan.longitude,
                    mekanName: mekan.name,
                    onTap: () => _openMaps(mekan.mapsUrl),
                  ),
                  const SizedBox(height: 24),
                  _buildAddressCard(mekan),
                  const SizedBox(height: 16),
                  _buildAgeCard(mekan),
                  const SizedBox(height: 32),
                  _buildCommentsSection(authProvider, mekanProvider, mekan),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(mekan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.accent.withValues(alpha: 0.2), AppColors.background],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20)),
            child: Text(mekan.categoryDisplayName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          const SizedBox(height: 16),
          Text(mekan.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            RatingStars(rating: mekan.rating, size: 24),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
              child: Text('${_yorumlar.length} yorum', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAddressCard(mekan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            const Text('Adres', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          Text(mekan.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _openMaps(mekan.mapsUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.map_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Haritada Aç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeCard(mekan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.people_rounded, color: AppColors.accent, size: 22),
        ),
        const SizedBox(width: 14),
        Text('${mekan.ageMin} - ${mekan.ageMax} yaş', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildCommentsSection(AuthProvider authProvider, MekanProvider mekanProvider, mekan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Yorumlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${_yorumlar.length}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 20),
        if (authProvider.isLoggedIn)
          AddCommentBox(onSubmit: _addYorum, isLoading: _isSubmittingYorum)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 32),
              const SizedBox(height: 12),
              const Text('Yorum yapmak için giriş yapın', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              GradientButton(text: 'Giriş Yap', onPressed: () => Navigator.pushNamed(context, AppConstants.loginRoute), width: 150),
            ]),
          ),
        const SizedBox(height: 24),
        if (_isLoadingYorumlar)
          ...List.generate(3, (i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: LoadingSkeleton(height: 120, borderRadius: BorderRadius.circular(16))))
        else if (_yorumlar.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('Henüz yorum yok', style: TextStyle(color: AppColors.textMuted, fontSize: 16))))
        else
          ..._yorumlar.map((yorum) => CommentBox(
                yorum: yorum,
                isOwner: yorum.userId == authProvider.currentUser?.id,
                onDelete: yorum.userId == authProvider.currentUser?.id
                    ? () async {
                        await _yorumService.deleteComment(yorum.id!, authProvider.currentUser!.id!);
                        _loadYorumlar();
                        mekanProvider.refreshMekan(mekan.id!, userId: authProvider.currentUser?.id);
                      }
                    : null,
              )),
      ],
    );
  }
}
